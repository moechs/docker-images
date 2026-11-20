#!/usr/bin/env python3
"""Batch-check Docker Hub for newer base image tags and update Dockerfiles.

Only FROM instructions are rewritten. Pinned package versions declared via
ARG IMAGE_VERSION are left untouched, and a warning is printed for files
whose packages may need re-checking after a base image bump.

Examples:
    python3 scripts/update_base_images.py                    # report only
    python3 scripts/update_base_images.py --policy minor     # allow minor bumps
    python3 scripts/update_base_images.py --apply            # write Dockerfiles
    python3 scripts/update_base_images.py --include-self     # include moechs/*
    python3 scripts/update_base_images.py --json             # machine-readable
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

TOKEN_URL = "https://auth.docker.io/token"
TAGS_URL = "https://registry-1.docker.io/v2/{repo}/tags/list"
TIMEOUT = 20
MAX_WORKERS = 4

# Explicit overrides. Unlisted images fall back to `library/<name>` or `<name>`.
REPO_MAP = {
    "alpine": "library/alpine",
    "alpine/git": "alpine/git",
    "almalinux": "library/almalinux",
    "almalinux/9-init": "almalinux/9-init",
    "golang": "library/golang",
    "node": "library/node",
    "frugan/php": "frugan/php",
    "frugan/php-legacy": "frugan/php-legacy",
    "moechs/jdk": "moechs/jdk",
    "moechs/bitnami-postgresql": "moechs/bitnami-postgresql",
}

SELF_PREFIX = "moechs/"

FROM_RE = re.compile(r"^(FROM\s+)(?P<ref>[^\s#]+)(?P<rest>[^\n]*)$", re.I | re.M)
IMAGE_VERSION_RE = re.compile(r"^ARG IMAGE_VERSION=(.+)$", re.M)
NUM_RE = re.compile(r"\d+")
LINK_NEXT_RE = re.compile(r'<([^>]+)>;\s*rel="next"')


@dataclass
class Ref:
    path: Path
    old: str
    image: str
    tag: str | None
    pinned_package: bool
    image_version: str | None


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--policy",
        choices=("patch", "minor", "major"),
        default="patch",
        help="how far to bump: patch (default), minor, or major",
    )
    parser.add_argument(
        "--apply",
        action="store_true",
        help="write updated tags back into Dockerfiles (default: dry-run)",
    )
    parser.add_argument(
        "--include-self",
        action="store_true",
        help=f"also check {SELF_PREFIX}* images (usually self-built)",
    )
    parser.add_argument(
        "--json", action="store_true", help="emit JSON instead of a table"
    )
    parser.add_argument(
        "--fail-on-update",
        action="store_true",
        help="exit 1 when updates are available (useful in CI)",
    )
    return parser.parse_args()


def skeleton(tag: str) -> str:
    """Replace digit runs with '#', e.g. 9.9-20261116 -> #.#-#."""
    return NUM_RE.sub("#", tag)


def numbers(tag: str) -> tuple[int, ...]:
    return tuple(int(x) for x in NUM_RE.findall(tag))


def version_part(tag: str) -> str:
    """Strip qualifiers: 8.2.36-fpm -> 8.2.36, v2.54.2 -> v2.54.2."""
    matches = list(NUM_RE.finditer(tag))
    return tag[: matches[-1].end()] if matches else tag


def is_candidate(current: str, candidate: str, policy: str) -> bool:
    if skeleton(current) != skeleton(candidate):
        return False
    cur, new = numbers(current), numbers(candidate)
    if len(cur) != len(new) or not cur or new <= cur:
        return False
    if policy == "patch":
        return new[:-1] == cur[:-1]
    if policy == "minor":
        return len(cur) < 2 or new[0] == cur[0]
    return True


def resolve_repo(image: str) -> str:
    """Map a FROM image name to a Docker Hub repository path."""
    if image in REPO_MAP:
        return REPO_MAP[image]
    if "/" in image:  # user/repo or official subpath, e.g. alpine/git
        return image
    return f"library/{image}"


def http_get(url: str, headers: dict[str, str] | None = None) -> tuple[bytes, dict]:
    req = urllib.request.Request(url, headers=headers or {})
    with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
        return resp.read(), dict(resp.headers)


def fetch_tags(repo: str) -> list[str]:
    scope = urllib.parse.quote(f"repository:{repo}:pull", safe=":")
    body, _ = http_get(f"{TOKEN_URL}?service=registry.docker.io&scope={scope}")
    token = json.loads(body)["token"]

    url = TAGS_URL.format(repo=repo)
    headers = {"Authorization": f"Bearer {token}", "Accept": "application/json"}
    tags: list[str] = []
    for _ in range(50):  # guard against runaway pagination
        body, meta = http_get(url, headers)
        tags.extend(json.loads(body).get("tags") or [])
        link = meta.get("Link", "")
        match = LINK_NEXT_RE.search(link)
        if not match:
            break
        url = match.group(1)
    return tags


def collect_refs() -> tuple[list[Ref], list[str]]:
    refs: list[Ref] = []
    issues: list[str] = []
    for path in sorted(ROOT.glob("*/Dockerfile")):
        text = path.read_text(encoding="utf-8")
        pinned = "ARG IMAGE_VERSION=" in text and "${IMAGE_VERSION}" in text
        version_match = IMAGE_VERSION_RE.search(text)
        image_version = version_match.group(1).strip() if version_match else None
        for match in FROM_RE.finditer(text):
            ref = match.group("ref")
            if "$" in ref:  # variable-based image, cannot resolve statically
                issues.append(f"{path.name}: 跳过变量镜像 {ref}")
                continue
            image, sep, tag = ref.partition(":")
            refs.append(
                Ref(path, ref, image, tag if sep else None, pinned, image_version)
            )
    return refs, issues


def main() -> int:
    args = parse_args()
    refs, issues = collect_refs()

    targets: dict[str, list[Ref]] = {}
    for ref in refs:
        if ref.tag is None or not numbers(ref.tag):
            issues.append(f"{ref.path.parent.name}: 未固定版本（{ref.old}），无法比较")
            continue
        if ref.image.startswith(SELF_PREFIX) and not args.include_self:
            issues.append(f"{ref.path.parent.name}: 跳过自维护镜像 {ref.old}")
            continue
        repo = resolve_repo(ref.image)
        targets.setdefault(repo, []).append(ref)

    tag_cache: dict[str, list[str] | None] = {}
    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as pool:
        futures = {pool.submit(fetch_tags, repo): repo for repo in targets}
        for future in as_completed(futures):
            repo = futures[future]
            try:
                tag_cache[repo] = future.result()
            except (urllib.error.URLError, TimeoutError, KeyError, ValueError) as exc:
                tag_cache[repo] = None
                issues.append(f"查询 {repo} 失败：{exc}")

    updates: list[dict] = []
    for repo, group in targets.items():
        tags = tag_cache.get(repo)
        if tags is None:
            continue
        for ref in group:
            newest = None
            for tag in tags:
                if is_candidate(ref.tag, tag, args.policy):
                    if newest is None or numbers(tag) > numbers(newest):
                        newest = tag
            if newest:
                # Keep IMAGE_VERSION in sync only when it mirrors the base tag
                # (e.g. node:26.13.1 / IMAGE_VERSION=26.13.1), not when it is
                # an application version (e.g. ansible 7.7.0 on almalinux).
                synced_version = None
                if ref.image_version and numbers(ref.image_version) == numbers(ref.tag):
                    synced_version = version_part(newest)
                updates.append(
                    {
                        "project": ref.path.parent.name,
                        "file": str(ref.path.relative_to(ROOT)),
                        "current": ref.old,
                        "new": f"{ref.image}:{newest}",
                        "policy": args.policy,
                        "check_packages": ref.pinned_package,
                        "image_version": synced_version,
                    }
                )

    if args.apply and updates:
        by_file: dict[Path, dict[str, str]] = {}
        for item in updates:
            by_file.setdefault(ROOT / item["file"], {})[item["current"]] = item["new"]
        for path, replacements in by_file.items():
            text = path.read_text(encoding="utf-8")
            for old, new in replacements.items():
                pattern = re.compile(rf"(?m)^(FROM\s+){re.escape(old)}(?=\s|$)")
                text = pattern.sub(lambda m: m.group(1) + new, text)
            for item in updates:
                if ROOT / item["file"] != path or not item["image_version"]:
                    continue
                text = IMAGE_VERSION_RE.sub(
                    f"ARG IMAGE_VERSION={item['image_version']}", text, count=1
                )
            path.write_text(text, encoding="utf-8")

    if args.json:
        print(json.dumps({"updates": updates, "issues": issues}, indent=2))
    else:
        if updates:
            print(f"{'PROJECT':<28} {'CURRENT':<32} {'NEW':<32} NOTE")
            for item in updates:
                notes = []
                if item["image_version"]:
                    notes.append(f"IMAGE_VERSION -> {item['image_version']}")
                if item["check_packages"]:
                    notes.append("检查包版本兼容性")
                print(
                    f"{item['project']:<28} {item['current']:<32} "
                    f"{item['new']:<32} {'; '.join(notes)}"
                )
        else:
            print(f"按 {args.policy} 策略未发现可更新的基础镜像。")
        if issues:
            print("\n跳过项：")
            for issue in issues:
                print(f"  - {issue}")
        if args.apply and updates:
            print(f"\n已写入 {len(updates)} 处变更（未提交）。")

    return 1 if args.fail_on_update and updates else 0


if __name__ == "__main__":
    sys.exit(main())

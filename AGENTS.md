# Project map

This repository maintains Docker images and their GitHub Actions automation. It does not contain application source code.

## Repository layout

- `<image>/Dockerfile`: one top-level directory equals one Docker build context and one published image variant.
- `scripts/update_base_images.py`: checks Docker Hub for newer base-image tags and rewrites `FROM` lines.
- `.github/workflows/base-image-update.yml`: daily scheduled update check and PR creation.
- `.github/workflows/docker-build.yml`: reusable multi-arch build, digest push, manifest merge, and tag publishing workflow.
- `.github/workflows/<image>.yml`: per-image trigger that calls `docker-build.yml` with `context: <image>`.

## Automated flow

1. `base-image-update.yml` runs at `0 3 * * *` UTC and on `workflow_dispatch`.
2. It runs `python3 scripts/update_base_images.py --policy patch --apply --json`.
3. The script scans `*/Dockerfile`, fetches Docker Hub tags, updates eligible `FROM` lines, and writes JSON to `UPDATES_FILE`.
4. The workflow validates changed Dockerfiles, commits each project separately, force-pushes `chore/base-image-update`, and creates or refreshes one PR. It never auto-merges.
5. After the PR is merged to the default branch, each project workflow triggers on `<image>/**` and calls `docker-build.yml`.
6. `docker-build.yml` builds `linux/amd64` and `linux/arm64`, pushes by digest, creates a manifest list, and publishes tags.

## Dockerfile contract

Each Dockerfile must declare:

```dockerfile
ARG IMAGE_NAME=moechs/<name>
ARG IMAGE_VERSION=<tag-prefix>

FROM <upstream>:<pinned-tag>
```

- `IMAGE_NAME` is the Docker Hub repository.
- `IMAGE_VERSION` is the published tag prefix, not necessarily a semantic version.
- `FROM` must be pinned to an explicit tag; variable-based images are skipped by the update script.
- Later `ARG IMAGE_VERSION` declarations without values are for Docker build use; workflow parsers only read the first default value.
- The update script scans every `FROM`, including multi-stage Dockerfiles.

## Published tag semantics

`docker-build.yml` publishes:

- `${IMAGE_VERSION}` on the default branch: a mutable tag that always points to the latest build.
- `${IMAGE_VERSION}-YYYYMMDD` using `Asia/Shanghai`: an immutable, build-date tag for users who need a fixed image.

Do not manually append a date to `IMAGE_VERSION`; the build workflow already generates the dated tag. A `workflow_dispatch` run on a non-default branch publishes only the dated tag.

## Base-image update rules

`update_base_images.py` supports two comparison modes.

### Normal tags

Default mode uses `--policy patch` with `skeleton()` and `numbers()`:

- `patch`: all numeric parts except the last must be equal.
- `minor`: the first numeric part must be equal.
- `major`: any increase with the same skeleton is accepted.

Date-style upstream tags such as `9.9-20261116 -> 9.9-20261121` use this normal mode.

### Backport release tags

Tags shaped as:

```text
<x.y[-z]>-<qualifier>-v<a.b.c>
```

for example `7.4-fpm-v0.4.0`, are handled by a dedicated rule:

- The full `head` before `-v` must be identical, e.g. `7.4-fpm` only matches `7.4-fpm`.
- The release after `-v` must have exactly three numeric parts.
- Only an increasing release is accepted.
- This rule ignores `--policy`.
- `IMAGE_VERSION` is never changed for backport updates.

In the update JSON:

- `policy` is the CLI policy requested by the caller, usually `patch`.
- `rule` is the comparator that actually selected the update, either `patch`/`minor`/`major` or `backport`.
- `image_version` is populated only for normal tags whose numbers exactly mirror the current `FROM` tag.

Self-managed images under `moechs/` are skipped unless `--include-self` is passed. `REPO_MAP` can explicitly map image names to Docker Hub repositories; unmapped names fall back to `library/<name>` or the original name.

## EOL backport example: php-fpm-74

```dockerfile
ARG IMAGE_NAME=moechs/php-fpm
ARG IMAGE_VERSION=7.4.33

FROM frugan/php-legacy:7.4-fpm-v0.5.1
```

Meaning:

- `7.4.33` is the frozen final PHP source version and remains the stable `IMAGE_VERSION`.
- `7.4` is the locked PHP major.minor identity.
- `v0.5.1` is the upstream backport release for this EOL branch.
- A base release bump only changes `FROM`.
- Published tags are `moechs/php-fpm:7.4.33` and `moechs/php-fpm:7.4.33-YYYYMMDD`.

## Useful commands

```bash
python3 scripts/update_base_images.py
python3 scripts/update_base_images.py --json
python3 scripts/update_base_images.py --apply
python3 scripts/update_base_images.py --policy minor
python3 scripts/update_base_images.py --include-self
```

## Adding a new image

1. Create a top-level directory and a pinned Dockerfile.
2. Add a workflow in `.github/workflows/<image>.yml` with matching `paths: <image>/**` and `context: <image>`.
3. Add a `REPO_MAP` entry only if the upstream repository cannot be inferred.
4. Confirm the published `${IMAGE_VERSION}` and `${IMAGE_VERSION}-YYYYMMDD` tags after the first build.

## Operational notes

- Package compatibility after a base update is a manual review item; `check_packages` only produces a reminder.
- GitHub Actions uses Python 3.12.
- Docker Hub credentials come from `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` secrets.
- `IMAGE_VERSION` is also used for non-numeric variants; for example `almalinux` uses `app` to describe its default user/workdir variant.

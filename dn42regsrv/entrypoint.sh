#!/bin/sh

REPOURL=${REPOURL:-https://git:${AUTHTOKEN}@git.dn42.dev/dn42/registry.git}
REGDIR=${REGDIR:-/registry}
BRANCH=${BRANCH:-master}

git config --global --add safe.directory "${REGDIR}"
git config --global init.defaultBranch "${BRANCH}"

cd "${REGDIR}" &>/dev/null && git status &>/dev/null || (
  mkdir -p "${REGDIR}"
  cd "${REGDIR}"
  git init
  git remote add origin "${REPOURL}"
  git pull origin master
  git branch --set-upstream-to=origin/"${BRANCH}" "${BRANCH}"
  chown -R registry:registry "${REGDIR}"
)

exec su registry -s /bin/sh -c "exec /dn42regsrv -b \"${BIND:-[::]:8042}\" \
  -s /StaticRoot \
  -l \"${LOGLEVEL:-Info}\" \
  -d \"${REGDIR}\" \
  -p \"${BRANCH}\" \
  -i \"${INTERVAL:-60m}\" \
  -a \"${AUTOPULL:-true}\" \
  -t \"${AUTHTOKEN:-secret}\""

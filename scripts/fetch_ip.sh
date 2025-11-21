#!/usr/bin/env bash
set -euo pipefail

# Placeholder fetch script for third-party IP.
# Requires network access; pins should be recorded in third_party/README.md after fetch.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
THIRD="${ROOT_DIR}/third_party"
mkdir -p "${THIRD}"

clone_if_missing() {
  local repo_url="$1"
  local dir_name="$2"
  local commit="$3"
  if [ -d "${THIRD}/${dir_name}/.git" ]; then
    echo "[skip] ${dir_name} already present"
    return
  fi
  echo "[clone] ${dir_name} (${commit})"
  git clone --depth 1 "${repo_url}" "${THIRD}/${dir_name}"
  (cd "${THIRD}/${dir_name}" && git fetch --depth 1 origin "${commit}" && git checkout "${commit}")
}

# TODO: fill in pinned commits after first fetch
clone_if_missing https://github.com/enjoy-digital/litepcie   litepcie   master
clone_if_missing https://github.com/enjoy-digital/litedram   litedram   master
clone_if_missing https://github.com/enjoy-digital/liteiclink liteiclink master
clone_if_missing https://github.com/enjoy-digital/litex      litex      master
clone_if_missing https://github.com/ZipCPU/wb2axip           wb2axip    master

echo "Done. Record exact commits in third_party/README.md."

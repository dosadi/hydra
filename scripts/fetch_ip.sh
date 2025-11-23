#!/usr/bin/env bash
set -euo pipefail

# Fetch script for third-party IP (LitePCIe/LiteDRAM/LiteICLink/LiteX/wb2axip).
# Requires network access; pinned commits should be recorded in third_party/README.md after fetch.

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

# NOTE: The default branch names below are placeholders; after the first
# successful fetch, replace them with specific commit hashes and record
# those hashes in third_party/README.md for reproducibility.
clone_if_missing https://github.com/enjoy-digital/litepcie   litepcie   5a50f83f33b7ceea75a0b226893d3b74c2361e79
clone_if_missing https://github.com/enjoy-digital/litedram   litedram   8ca007a0372788d3d64cdc196220e729e6e940e3
clone_if_missing https://github.com/enjoy-digital/liteiclink liteiclink 679befc2271e64297345b15e974b2d2fdcd8fad5
clone_if_missing https://github.com/enjoy-digital/litex      litex      10c52e742094ce72884fb7f0711576a4f6fb4892
clone_if_missing https://github.com/ZipCPU/wb2axip           wb2axip    70f9d2b041742fb1823208c4ff4b0a099e669b5e

echo "Done. Remember to record exact commits in third_party/README.md."

#!/usr/bin/env bash
set -euo pipefail

# scripts/mark_exec_and_commit.sh
# Mark common helper scripts executable in git and commit the change.
# Run this from the repo root.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

FILES=(
  scripts/*.sh
  sim/*.sh
)

TO_SET=()
for f in ${FILES[@]}; do
    for path in $f; do
        [ -e "$path" ] || continue
        # Only mark regular files
        if [ -f "$path" ]; then
            TO_SET+=("$path")
        fi
    done
done

if [ ${#TO_SET[@]} -eq 0 ]; then
    echo "No candidate scripts found to mark executable."
    exit 0
fi

echo "Files to be marked executable and committed:" 
for p in "${TO_SET[@]}"; do echo "  $p"; done

read -r -p "Proceed to mark these files executable and commit? [y/N] " ans
if [[ "$ans" != "y" && "$ans" != "Y" ]]; then
    echo "Aborted."
    exit 1
fi

for p in "${TO_SET[@]}"; do
    git update-index --add --chmod=+x "$p"
done

git commit -m "chore(scripts): mark helper scripts executable" || true
echo "Committed executable bit changes (if any)."

exit 0

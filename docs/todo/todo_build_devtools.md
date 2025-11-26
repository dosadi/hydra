# Developer Tools & Build System TODOs

Divides the `todo_build_tooling.md` Developer Tools, Build System Refactoring, and Version Management sections so each focus gets dedicated attention.

## Developer Tools
- TODO [P2]: Produce Docker/devcontainer images for a reproducible toolchain (`docker build && docker run make test_frame` passes).
- TODO [P2]: Add `make shellcheck` (target exists, push to docs) to lint scripts consistently.
- TODO [P2]: Maintain the license header checker (`scripts/check_license_headers.py`) and ensure CI runs it.
- TODO [P2]: Build release artifacts via `make package` (tarball/zip containing sim + docs).
- TODO [P2]: Create a `scripts/dev_toolcheck.sh` that verifies required tools (clang-format, verilator, SDL2) and documents failures for new contributors.
- TODO [P3]: Publish developer quickstart for the devcontainer/Docker image describing hotkeys, HUD help, and common scripts.

## Build System Refactoring
- TODO [P2]: Align the Makefile and CMake flow so `make` simply delegates to CMake/Parellel builds while keeping existing RTL/Verilator commands.
- TODO [P2]: Examine Meson/Bazel alternatives for the host stack and evaluate whether they can produce the same artifacts.
- TODO [P2]: Support out-of-tree builds everywhere (no artifacts in `rtl/`); add a `BUILD_DIR` override for all scripts.
- TODO [P3]: Add `make quick` documentation describing when to use it vs `make`/`sim` to keep iterations fast for devs.

## Version & Release Automation
- TODO [P2]: Script version bumps (`scripts/bump_version.sh 0.0.7`) so README/CMake/UAPI see consistent updates.
- TODO [P2]: Automate release tagging (`scripts/create_release_tag.sh`), ensuring annotated tags reference changelog entries.
- TODO [P2]: Generate changelog notes from git commits (`scripts/generate_changelog.py`) so release notes are consistent.
- TODO [P3]: Add sanity checks post-tagging to verify installers/packages include the updated changelog/versions (stub script).

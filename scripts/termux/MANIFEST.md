Termux scripts manifest
=======================

This manifest lists the Termux-related helper scripts in `scripts/` and a
short description of each, intended to help onboard the pieces into the
project.

- `termux_preflight_check.sh`: Environment/info check to run on a Termux
  device. Outputs missing packages and suggested next steps. Can optionally
  install missing packages with `--install`.
- `termux_ssh_control.sh`: Start/stop/status helper for `sshd` inside Termux.
- `termux_proot_setup.sh`: Boots a `proot-distro` (Ubuntu), ensures build
  deps (including Verilator) are present inside the distro, clones the
  `hydra` repo, and attempts to run the AXI wrap test.
- `rsync_to_termux.sh`: Host-side rsync wrapper to push the repo to a
  Termux device over SSH. Includes conservative excludes.
- `rsync_pull_from_host.sh`: Run on Termux to pull sources from a host via
  rsync over SSH.
- `host_adb_ssh_control.sh`: Host-side helper that uses `adb shell` to
  install `openssh` in Termux and start `sshd` when a device is connected.

Notes:
- Scripts remain in `scripts/` for backward compatibility. Consider moving
  supported files into this `scripts/termux/` subfolder once their
  behavior is finalized.
- Add `shellcheck` linting as part of onboarding to catch common shell
  issues (I can add a Makefile target or CI job for this).

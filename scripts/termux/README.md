# Termux onboarding

This folder documents and collects helper scripts used to bootstrap, sync,
and run parts of the `hydra` repo on an Android Termux environment.

These scripts are intended to be run either on the host (your workstation)
or on the Termux device (Android). They are convenience helpers and may
install packages or perform destructive `rsync --delete` operations — read
the script contents before running them, especially when using the
`rsync_to_termux.sh` helper.

Location of scripts (sources kept at `scripts/`):

- `termux_preflight_check.sh` — run on Termux to verify installed tools
  and recommend next steps. Can optionally install missing packages.
- `termux_ssh_control.sh` — start/stop/status for `sshd` on Termux.
- `termux_proot_setup.sh` — bootstrap a `proot-distro` (Ubuntu) and install
  build dependencies (Verilator, SDL2, etc.), then clone this repo and
  attempt the AXI wrap test. Intended to be run on Termux.
- `rsync_to_termux.sh` — host-side rsync wrapper to sync the local repo to
  a Termux device via SSH. Uses conservative excludes by default.
- `rsync_pull_from_host.sh` — run on Termux to pull a host's repo via rsync
  (convenient when the host exposes SSH).
- `host_adb_ssh_control.sh` — host-side helper to use `adb` to start `sshd`
  inside Termux when a device is connected.

Onboarding checklist
- [ ] Review each script and confirm it matches your security policy.
- [ ] Move scripts you intend to support into `scripts/termux/` (this repo
      keeps them at `scripts/` already; consider reorganizing if desired).
- [ ] Optionally add automated tests / smoke checks (e.g., linting shell
      with `shellcheck`) and CI steps to validate changes.
- [ ] If you rely on these scripts in CI, add a matrix job with an emulator
      or a mocked environment; note that full Termux testing requires an
      Android device or emulator and isn't currently part of CI.

Security note
These scripts may copy files to a device, install packages, or run commands
with network access. Only run them against devices and hosts you control.

If you want, I can:

- Add `scripts/termux` directory and move canonical copies of the scripts
  there (leaving the existing top-level `scripts/` copies as compatibility
  symlinks), and add a `Makefile` target that runs `shellcheck`.
- Add a simple `scripts/termux/README.quickstart.md` with copyable commands
  for common flows (preflight -> proot -> run AXI test).

Tell me which of the above you'd like next.

## Windows Driver Installer Plan

This doc captures the plan for packaging the Hydra Windows driver for both x86 and x64.

### Contents

- `hydra_win32.dll` – x86 driver binary from `build/windows/Win32/Release`.
- `hydra_win64.dll` – x64 binary from `build/windows/x64/Release`.
- `hydra.inf` – INF file describing the device class and referencing both binaries.

### Installer script

- `scripts/windows-installer.sh` packages the binaries and writes a placeholder INF (`out/windows-installer/hydra.inf`). Update this script to copy the `.sys` file (renamed from `.dll` when final driver built) and include catalog signing info.

### Distribution

- The installer should include a catalog file (`.cat`) for the INF once signing is in place. Document steps in this doc for generating the catalog and linking the appropriate certificate.

### Testing

- Install the package on Windows 10/11 test VMs (both Win32 and x64) using `pnputil /add-driver`.
- Document verification commands (e.g., `sc query hydra`, `Get-PnpDevice`).

Reference this planner from `docs/todo/todo_mesa_drivers.md` under the Windows driver section.

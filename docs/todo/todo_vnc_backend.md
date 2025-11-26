# VNC Backend TODOs

Back-end support for remote viewing, automation, and CI-friendly captures via a VNC-targeted renderer.

- TODO [P1]: Define the command-line entry point and configuration schema (display size, pixel format, authentication, logging) for the VNC backend so it can be invoked from CI and automation scripts.
- TODO [P1]: Wire the VNC backend into `sim/` as a platform option (e.g., `sim_voxel --platform vnc`) and document how it interacts with the SDL viewer and headless modes.
- TODO [P2]: Implement automatic framebuffer capture and compression hooks so the VNC backend can stream to CI dashboards without waiting on SDL.
- TODO [P2]: Add idle/time-slice throttling and token bucket rate-limiting to the VNC server loop to keep rendering latencies consistent under automated replay.
- TODO [P2]: Integrate the backend with `scripts/automation_watchdog.sh` and `ai_health_dashboard` outputs so rendered frames can be archived to `out/vnc_frames/` and referenced by TODO automation.
- TODO [P3]: Document how to secure the VNC connection (password support, optional TLS tunnel stub, firewall guidance) and link it from `docs/todo/todo_security.md`.
- TODO [P3]: Add regression coverage (unit test or nightly job) that spins up the VNC backend, connects with `vnctool`, asserts frame checksum/CRC, and dumps artifacts to `out/vnc_crc`.
- TODO [P2]: Collaborate with `todo_platform_backends.md` to add a dependency note so other viewers know when VNC-rendered assets require shader alignment or framebuffer format changes.
- TODO [P3]: Capture a list of visualization improvements unique to VNC (palette changes, HDR/SDR options, color space toggles) and feed them into `docs/todo/todo_rendering.md`.

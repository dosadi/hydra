Hydra sim Docker runner
=======================

This directory contains a minimal `Dockerfile` and helper script to build and run the Verilator + SDL sim (`sim_voxel`) inside a container.

Files
- `Dockerfile` — image that installs build deps and runs `make` in `sim/` to produce `sim_voxel`.
- `run_container.sh` — build/run helper (supports `--gui` to forward X11).
- `run_sim.sh` — local launcher (existing) that prefers `tmux` and falls back to `nohup`.

Build

From the `sim/` directory:

```bash
./run_container.sh build
```

This builds `hydra-sim:local`. The build will run `make` inside the image; it may take several minutes.

Run (GUI)

To run the sim with X11 forwarding (so the SDL window appears on your host):

```bash
# on host: allow local connections (if needed)
xhost +local:root

./run_container.sh run --gui
```

Notes:
- The script mounts the repo into `/workspace` inside the container and runs `/workspace/sim/sim_voxel`.
- If your environment uses `XAUTHORITY`, `run_container.sh` will bind it into the container.

Run (headless)

```bash
./run_container.sh run
```

Environment knobs
- `HYDRA_FONT` — path to a TTF font inside the container (or host path when volume-mounted).
- `HYDRA_FOG`, `HYDRA_FOG_COLOR`, `HYDRA_FOG_DENSITY` — fog runtime controls.
- `HYDRA_RENDER_INSTRUMENT` — enable render instrumentation.

Troubleshooting
- If you see SDL complaining about missing fonts, set `HYDRA_FONT` to a valid TTF file inside the container (e.g., `/workspace/some-font.ttf`).
- For Wayland or other display servers, you may need a different bind or compositor setup; this helper focuses on classic X11 forwarding.

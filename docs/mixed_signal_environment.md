# Mixed-Signal Simulation Environment

This document captures the current setup for VAMS/Spice/Xyce/Matlab based board simulations so that analog verification stays reproducible.

## Tools
- **VAMS / ModelSim** (`vsim`): obtains the analog/mixed-signal models (license-protected). Export expected location: `$(which vsim)`.
- **NgSpice** (`ngspice`): open-source analog simulator used for smaller analog circuits and diff-netlist dumps.
- **Xyce** (`xyce`): silicon-focused SPICE solver for high-performance runs.
- **Matlab/Octave**: used for waveform analysis and regression plots.

## Environment Layout
Run `scripts/setup_mixed_signal_env.sh` to initialize:
- `MIXED_SIGNAL_HOME` (defaults to `$PWD/mixed_signal_env/`).
- `models/` for downloaded SPICE decks or VAMS models.
- `logs/` for simulation output and regression artifacts.
- `results/` to store waveform exports and hashed signatures.

## Workflow
1. Source the script and verify each tool is available. The script will point out missing binaries and set env vars.
2. Place `xschem` generated netlists into `models/` and invoke `xschem_to_vams.py` (TBD) to convert.
3. Run `scripts/board_simulate.sh` to run the selected analog engine, save waveforms under `logs/`, and compute diff hashes under `results/`.
4. Feed the regression logs back into `docs/todo/todo_board_hardware_design.md` and `scripts/todo_sweep.py` if needed.

## Licensing and Notes
- VAMS/ModelSim requires a valid `LM_LICENSE_FILE` environment variable. The script will remind you to set it if it is missing.
- Keep `mixed_signal_env/models/README.md` updated with model versions/hashes and reference them in release notes.

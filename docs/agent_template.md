# Agent Documentation Template

Use this template when creating documentation for new AI agents working on the Hydra repository.

## {AGENT_NAME}.md

This file provides guidance to {AGENT_NAME} when working with code in this repository.

## Project Overview

Hydra is a voxel-based 3D graphics accelerator with a SystemVerilog raycaster core, PCIe device interface, and Verilator+SDL2 interactive viewer. It implements a 64×64×64 voxel volume with hardware ray marching, live camera control, and voxel editing.

## Agent-Specific Features

*[Describe any special capabilities or requirements specific to this agent]*

## Core Commands

### Building and Testing

```bash
# Main development loop (builds sim, runs frame regression, builds SDK, optional RTL/QEMU)
./scripts/hydra_dev_loop.sh

# Build and run the interactive viewer
cd sim && make && ./sim_voxel

# Run frame regression test only
make -C sim test_frame

# Build SDK tools (libhydra + smoketests)
./scripts/setup_sdk.sh

# Build Linux driver (requires kernel headers)
make -C drivers/linux

# Run RTL benches (requires iverilog/vvp)
sim/tests/run_rtl_tests.sh
```

### Viewer Controls and Debugging

```bash
# Enable per-frame stats logging
LOG_FRAMES=1 ./sim_voxel

# Log keyboard events
LOG_KEYS=1 ./sim_voxel

# Non-interactive: dump single frame as PPM and exit
FRAME_DUMP=frame.ppm AUTO_EXIT=1 ./sim_voxel

# Interactive viewer controls:
# - WASD/QE: fly camera
# - Mouse: look around
# - F: select voxel at screen center
# - Number keys: toggle render flags
# - O: toggle diagnostic slice renderer
```

## Automation and CI/CD

### Priority Automation Script

The repository includes a comprehensive automation script that orchestrates quality checks, testing, and maintenance tasks:

```bash
# Run all automation sectors (build, test, quality, docs, benchmark, security, integration)
./scripts/automate_priority.sh

# Run specific sectors only
./scripts/automate_priority.sh --build-only --test-only

# Skip specific sectors
./scripts/automate_priority.sh --skip-security --skip-integration

# Dry run to see what would be executed
./scripts/automate_priority.sh --dry-run
```

### Automated TODO Management

GitHub Actions workflows automatically manage TODO tracking and validation:

- **todo-automation.yml**: Scheduled daily checks for TODO status, generates reports, and validates TODO metadata
- **ci.yml**: Comprehensive CI pipeline with build, test, and quality checks
- **pr-validation.yml**: Pull request validation with automated checks

### Top-Level Automation Orchestrator

For comprehensive project automation, use the top-level orchestrator:

```bash
# Full automation suite (all checks, builds, tests, maintenance)
./scripts/automate_top_level.sh full

# Quick automation (fast feedback subset)
./scripts/automate_top_level.sh quick

# Agent coordination checks
./scripts/automate_top_level.sh agents

# Dry run to see what would be executed
./scripts/automate_top_level.sh --dry-run full
```

Or use Makefile targets:

```bash
make automate-top-level  # Full automation
make automate-quick      # Quick checks
make automate-agents     # Agent coordination
```

### Automated CI/CD

GitHub Actions provides automated workflows:

- **top-level-automation.yml**: Scheduled daily comprehensive automation with reporting
- **ci.yml**: Full CI pipeline on pushes/PRs
- **todo-automation.yml**: Automated TODO management and validation

### Agent Coordination Automation

When multiple agents work on the repository:

1. **Check coordination status**: Review `docs/agent_integration_bridge.md`
2. **Run health checks**: Execute `./scripts/todo_sweep.py` and `./scripts/check_required_files.py`
3. **Document work**: Update continuity logs and TODO trackers
4. **Use lock coordination**: For shared resources, follow protocols in `docs/rfc/lock_coordination.md`

## Session Management

*[Describe how this agent should coordinate with other agents]*

## Architecture Summary

*[Include key architecture details relevant to this agent]*

## Testing Strategy

*[Include testing approach tailored to this agent]*

## Additional Resources

- **Agent coordination**: `docs/agent_integration_bridge.md`
- **AI resource strategy**: `docs/ai_resource_strategy.md`
- **Component maturity**: `docs/component_status.md`
- **Driver bring-up**: `docs/driver_integration.md`
- **Hardware validation**: `docs/hardware_test_plan.md`
## Description

<!-- Provide a clear summary of what changed and why -->

## Type of Change

<!-- Mark the relevant option(s) with an 'x' -->

- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to change)
- [ ] Documentation update
- [ ] Refactoring (no functional changes)
- [ ] Build/CI changes
- [ ] Performance improvement

## Component(s) Affected

<!-- Mark all that apply -->

- [ ] RTL (voxel core, raycaster, shell)
- [ ] Sim (Verilator+SDL viewer)
- [ ] Drivers (Linux/FreeBSD/Windows/macOS)
- [ ] Build system (Makefile/CMake)
- [ ] Documentation
- [ ] CI/CD
- [ ] Testing infrastructure

## Testing Performed

<!-- Describe how you validated your changes -->

**Commands run:**
```bash
# Example:
# ./scripts/hydra_dev_loop.sh
# make -C sim test_frame
# cd sim && ./sim_voxel
```

**Test results:**
- [ ] Sim builds successfully (`make -C sim`)
- [ ] Frame regression passes (`make -C sim test_frame`)
- [ ] Interactive viewer works (`./sim_voxel`)
- [ ] SDK tools build (`./scripts/setup_sdk.sh`)
- [ ] RTL benches pass (if applicable)
- [ ] Visual inspection confirms expected behavior

**Platform(s) tested:**
- [ ] Linux (Debian/Ubuntu)
- [ ] Linux (other distro)
- [ ] FreeBSD
- [ ] Windows (WSL2/native)
- [ ] macOS

## Screenshots/Videos

<!-- If this PR includes visual changes, include screenshots or short video clips -->

## Breaking Changes

<!-- If this is a breaking change, describe the impact and migration path -->

## Related Issues

<!-- Link related issues using GitHub keywords -->
<!-- Example: Fixes #123, Closes #456, Related to #789 -->

## Additional Context

<!-- Any other information reviewers should know -->
<!-- Examples: -->
<!-- - New dependencies added -->
<!-- - Known limitations or deferred work -->
<!-- - Register map changes (update docs/hydra_spec.md) -->
<!-- - Golden frame updated (explain why) -->

## Checklist

<!-- Ensure all applicable items are complete before requesting review -->

- [ ] My code follows the coding style of this project (see `CONTRIBUTING.md`)
- [ ] I have read the `CONTRIBUTING.md` document
- [ ] I have added/updated tests that prove my fix/feature works
- [ ] All existing tests pass (`./scripts/hydra_dev_loop.sh`)
- [ ] I have updated documentation if needed
- [ ] For RTL changes: Waveforms inspected and key signals verified
- [ ] For register map changes: `docs/hydra_spec.md` and UAPI headers updated
- [ ] For visual changes: Golden frame updated with justification
- [ ] Commit messages are clear and follow project conventions (short, imperative)
- [ ] No unrelated formatting changes or trailing whitespace

## Notes for Reviewers

<!-- Highlight areas that need special attention or where you'd like feedback -->

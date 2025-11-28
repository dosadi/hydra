# Release Workflow Documentation

This document outlines the complete release workflow for Hydra, including versioning, tagging, changelog management, and quality gates.

## Release Versioning

Hydra follows semantic versioning with a `MAJOR.MINOR.PATCH` format:

- **MAJOR**: Breaking changes to API, UAPI, or hardware interfaces
- **MINOR**: New features, significant improvements
- **PATCH**: Bug fixes, documentation updates, minor improvements

### Pre-Release Versions
- **Alpha** (`0.0.x-alpha`): Early development, unstable APIs
- **Beta** (`0.0.x-beta`): Feature-complete but needs testing
- **RC** (`0.0.x-rc.N`): Release candidate, ready for production

### Current Status
- **Current Version**: 0.0.7 (development)
- **Next Version**: 0.0.8 (planned features: IP integration, hardware bring-up)

## Release Cadence

### Regular Releases
- **Patch releases**: As needed for critical fixes
- **Minor releases**: Monthly, feature-driven
- **Major releases**: When API stability achieved (1.0.0+)

### Release Branches
```
main          # Development branch
release/0.0.x # Release stabilization branch
hotfix/0.0.x  # Critical fix branch (if needed)
```

## Release Process

### Phase 1: Preparation (1-2 weeks before)

#### 1. Create Release Branch
```bash
git checkout main
git pull origin main
git checkout -b release/0.0.8
```

#### 2. Update Version Numbers
Update version in key files:
```bash
# RTL version constants
vim rtl/voxel_axil_csr.sv  # Update REV_ID, BUILD_ID

# Documentation
vim docs/hydra_spec.md     # Update version references

# Build system
vim CMakeLists.txt         # Update project version
```

#### 3. Run Pre-Release Checks
```bash
# Build verification
make clean && make
cd sim && make clean && make && ./sim_voxel --version

# Test suite
cd sim && make test
python3 scripts/todo_sweep.py
python3 scripts/check_required_files.py

# Documentation validation
make doxygen
```

#### 4. Update Release Notes
Create or update `docs/release_notes_0_0_8.md`:

```markdown
# Hydra 0.0.8 Release Notes

## Highlights
- [Major feature 1]
- [Major feature 2]
- [Breaking change notice]

## New Features
- [Feature descriptions]

## Bug Fixes
- [Fix descriptions]

## Breaking Changes
- [API/hardware changes]

## Tooling & Infrastructure
- [Build/doc improvements]

## Testing Recommendations
- [Test procedures]
```

### Phase 2: Stabilization (3-5 days)

#### 1. Create Release Checklist
Create `docs/release_checklist_0_0_8.md` based on template:

```markdown
# Hydra 0.0.8 Release Checklist

## Code Quality
- [ ] All P0 TODOs resolved
- [ ] CI passing on all platforms
- [ ] Code review completed
- [ ] Documentation updated

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Performance benchmarks met
- [ ] Compatibility testing completed

## Release Artifacts
- [ ] Version numbers updated
- [ ] Changelog finalized
- [ ] Release notes published
- [ ] Tags created and signed
```

#### 2. Quality Gates
**Must Pass Before Release:**
- [ ] `make` builds successfully
- [ ] `make test` passes all tests
- [ ] `make doxygen` generates docs
- [ ] `python3 scripts/todo_sweep.py` reports no critical issues
- [ ] Manual testing: `./sim_voxel` runs and renders correctly

**Should Pass:**
- [ ] Cross-platform builds (Linux, FreeBSD, Windows)
- [ ] Performance regression tests
- [ ] Documentation links valid

#### 3. Final Documentation Updates
```bash
# Update component status
vim docs/component_status.md

# Update API documentation
make doxygen

# Validate all docs
python3 scripts/docs_lint.py
```

### Phase 3: Release (1 day)

#### 1. Final Commit
```bash
git add -A
git commit -m "Release 0.0.8

- [Major changes]
- [Bug fixes]
- [Documentation updates]

Signed-off-by: [Name] <email>"
```

#### 2. Create and Push Tag
```bash
# Create annotated tag
git tag -a v0.0.8 -m "Hydra 0.0.8

[Release notes summary]

Signed-off-by: [Name] <email>"

# Push tag to origin
git push origin v0.0.8
```

#### 3. GitHub Release
Create GitHub release with:
- **Tag**: `v0.0.8`
- **Title**: `Hydra 0.0.8`
- **Description**: Copy from `docs/release_notes_0_0_8.md`
- **Assets**: Attach release artifacts if any

#### 4. Post-Release Updates
```bash
# Merge back to main
git checkout main
git merge release/0.0.8

# Update development version
# Bump version to 0.0.9-dev in relevant files
```

## Release Checklist Template

Use this template for each release:

```markdown
# Hydra [VERSION] Release Checklist

## Pre-Release
- [ ] Create release branch: `git checkout -b release/[VERSION]`
- [ ] Update version numbers in RTL, docs, build files
- [ ] Run full test suite: `make test`
- [ ] Update release notes: `docs/release_notes_[VERSION].md`
- [ ] Create release checklist: `docs/release_checklist_[VERSION].md`

## Quality Assurance
- [ ] Code review completed
- [ ] CI passing on all supported platforms
- [ ] Documentation updated and validated
- [ ] Performance benchmarks met
- [ ] Manual testing completed

## Release
- [ ] Final commit with release notes
- [ ] Create annotated tag: `git tag -a v[VERSION]`
- [ ] Push tag: `git push origin v[VERSION]`
- [ ] Create GitHub release
- [ ] Merge release branch back to main
- [ ] Update to next development version

## Post-Release
- [ ] Announce release on relevant channels
- [ ] Monitor for critical issues
- [ ] Plan next release cycle
```

## Changelog Management

### CHANGELOG.md Format
```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- New features

### Changed
- Changes in existing functionality

### Deprecated
- Soon-to-be removed features

### Removed
- Removed features

### Fixed
- Bug fixes

### Security
- Security-related changes

## [0.0.8] - 2025-11-26

### Added
- Performance tuning guide
- RTL signal reference documentation
- Doxygen API documentation generation

### Fixed
- Documentation build issues
- TODO tracker inconsistencies

### Changed
- Updated release workflow documentation
```

### Automatic Changelog Generation
```bash
# Generate changelog from git history
git log --pretty=format:"%h %s" v0.0.7..HEAD > changes.txt

# Or use conventional commits
# See: https://www.conventionalcommits.org/
```

## Branching Strategy

### Development Workflow
```
main (protected)
├── feature/* (feature branches)
├── bugfix/* (bug fix branches)
└── release/* (release stabilization)
    └── hotfix/* (critical fixes)
```

### Merge Strategy
- **Feature branches**: Squash merge to main
- **Release branches**: Merge commit to main after tagging
- **Hotfix branches**: Cherry-pick to release and main

## Release Automation

### Scripts Used
- `scripts/todo_sweep.py` - Validate TODO tracker integrity
- `scripts/check_required_files.py` - Verify required files exist
- `scripts/docs_lint.py` - Check documentation validity
- `scripts/release_prep.sh` - Automate version bumping (if exists)

### CI Integration
```yaml
# .github/workflows/release.yml
name: Release
on:
  push:
    tags:
      - 'v*'
jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build
        run: make
      - name: Test
        run: make test
      - name: Create Release
        uses: actions/create-release@v1
        # ... release creation steps
```

## Rollback Procedures

### If Release Fails
1. **Delete tag**: `git tag -d v0.0.8 && git push origin :v0.0.8`
2. **Delete GitHub release** through web interface
3. **Fix issues** in release branch
4. **Re-tag** with corrected version

### If Critical Bug Found
1. **Create hotfix branch**: `git checkout -b hotfix/0.0.8.1 v0.0.8`
2. **Fix bug** and test
3. **Create patch version**: `v0.0.8.1`
4. **Cherry-pick** to main if appropriate

## Communication

### Release Announcements
- **Internal**: Slack/Teams channel
- **External**: GitHub releases, mailing list
- **Social**: Twitter/Mastodon if applicable

### Release Notes Template
```markdown
# Hydra [VERSION] Release Notes

## Highlights
- [3-5 bullet points of major changes]

## New Features
- [Detailed feature list]

## Bug Fixes
- [Critical fixes and improvements]

## Breaking Changes
- [API/hardware changes requiring attention]

## Tooling & Infrastructure
- [Build/doc/testing improvements]

## Testing Recommendations
- [How to validate the release]

## Known Issues
- [Any remaining issues or limitations]

## Contributors
- [List of contributors]

## Acknowledgments
- [Special thanks]
```

## Quality Metrics

### Release Criteria
- **Test Coverage**: >80% for critical paths
- **Performance**: No regression >5% from previous release
- **Compatibility**: Works on all supported platforms
- **Documentation**: All new features documented

### Success Metrics
- **Time to release**: <1 week from branch creation
- **Bug reports**: <5 critical issues in first week
- **Adoption**: Download/install success rate >95%

## Troubleshooting

### Common Issues
1. **Version mismatch**: Check all version references
2. **Test failures**: Run tests locally first
3. **Documentation stale**: Update docs before tagging
4. **Tag conflicts**: Use unique version numbers

### Getting Help
- Check `docs/release_checklist_[VERSION].md` for specific issues
- Review previous releases for patterns
- Contact release manager or maintainers

---

**Document Version:** 1.0
**Last Updated:** 2025-11-26
**Related Documents:**
- `docs/release_checklist_0_0_3.md` (example checklist)
- `docs/release_notes_0_0_7.md` (example release notes)
- `docs/TODO_MASTER_INDEX.md` (current priorities)
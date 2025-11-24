# Recommended GitHub Repository Settings

This document outlines recommended GitHub repository settings for Hydra to ensure code quality and protect the main branch.

## Branch Protection Rules

### Main Branch (`main`)

Configure branch protection via: Settings → Branches → Add rule (pattern: `main`)

**Recommended Settings:**

✅ **Require a pull request before merging**
- Require approvals: 1 (adjust based on team size)
- Dismiss stale pull request approvals when new commits are pushed
- Require review from Code Owners (once CODEOWNERS is configured)

✅ **Require status checks to pass before merging**
- Require branches to be up to date before merging
- Required status checks:
  - `linux` (from ci.yml workflow)
  - `cocotb` (from ci.yml workflow) - Optional: set as required or allow bypass
  - `freebsd-kmod` (from ci.yml workflow) - Optional: set as required or allow bypass

⚠️ **Require conversation resolution before merging**
- Ensures all review comments are addressed

⚠️ **Require signed commits** (Optional but recommended)
- Ensures commit authenticity with GPG signatures

✅ **Require linear history** (Optional)
- Enforces rebase or squash merges for cleaner history
- Recommendation: Enable if you prefer linear git history

❌ **Do not allow force pushes**
- Protects against accidental history rewrites

✅ **Do not allow deletions**
- Prevents accidental branch deletion

## General Repository Settings

### Settings → General

**Pull Requests:**
- ✅ Allow squash merging (recommended)
- ✅ Allow merge commits (optional)
- ✅ Allow rebase merging (optional)
- ✅ Automatically delete head branches (keeps repo clean)

**Issues:**
- ✅ Enable Issues
- ✅ Use issue templates (configured in ISSUE_TEMPLATE/)

**Discussions:**
- Optional: Enable Discussions for community Q&A

**Wikis:**
- Optional: Enable if additional documentation is needed beyond docs/

### Settings → Actions → General

**Actions permissions:**
- ✅ Allow all actions and reusable workflows (if using third-party actions)
- OR: ✅ Allow select actions (for tighter control)

**Workflow permissions:**
- ✅ Read and write permissions (needed for artifact uploads)
- ✅ Allow GitHub Actions to create and approve pull requests (for Dependabot)

**Fork pull request workflows:**
- ⚠️ Require approval for first-time contributors (security)

### Settings → Security & Analysis

**Dependabot:**
- ✅ Dependabot alerts (auto-enabled for public repos)
- ✅ Dependabot security updates
- ✅ Dependabot version updates (configured in dependabot.yml)

**Private vulnerability reporting:**
- ✅ Enable (allows researchers to privately report security issues)

**Secret scanning:**
- ✅ Enable (auto-enabled for public repos)

## Collaborators & Teams

### Settings → Collaborators and teams

**Team Structure (if applicable):**
- `@org/hydra-core` - Full admin access
- `@org/hydra-rtl` - Write access to /rtl, /sim
- `@org/hydra-drivers` - Write access to /drivers
- `@org/hydra-contributors` - Write access to documentation

**Individual Contributors:**
- Core maintainers: Admin or Maintain role
- Regular contributors: Write role
- External contributors: Fork + PR workflow

## Rulesets (Alternative to Branch Protection)

GitHub Rulesets (Beta) provide more flexible branch protection:

**If using Rulesets instead of Branch Protection:**

1. Create ruleset: Settings → Rules → Rulesets → New ruleset
2. Target: Default branch (`main`)
3. Rules:
   - Require pull request before merging (1 approval)
   - Require status checks to pass
   - Block force pushes
   - Restrict deletions

**Advantages:**
- Can target multiple branches with patterns
- More granular bypass permissions
- Can apply to tags as well

## Repository Topics

Add these topics to improve discoverability:

Settings → General → Topics:
- `voxel`
- `raycaster`
- `rtl`
- `systemverilog`
- `verilator`
- `pcie`
- `fpga`
- `graphics-accelerator`
- `hardware`
- `3d-graphics`
- `sdl2`

## Social Preview

Settings → General → Social preview:

Upload a preview image (1280x640 recommended) showing:
- Hydra logo or branding
- Screenshot of the SDL viewer with voxel scene
- Project tagline: "Voxel-Based 3D Graphics Accelerator"

## Project Description

Settings → General → Description:

Suggested: "Voxel-based 3D graphics accelerator with SystemVerilog raycaster core and Verilator+SDL2 interactive viewer"

Website: Link to documentation site or GitHub Pages if applicable

## GitHub Pages (Optional)

If you want to publish documentation:

1. Settings → Pages
2. Source: Deploy from a branch → `gh-pages` or `docs/`
3. Use MkDocs or similar to generate from docs/ markdown

## Applying These Settings

Most settings require repository admin access:

1. Review this document with repository owner/admin
2. Apply settings incrementally (start with branch protection)
3. Test with a non-critical PR before enforcing all rules
4. Document any deviations from these recommendations

## Checklist

After configuring:

- [ ] Branch protection enabled for `main`
- [ ] Required status checks configured
- [x] CODEOWNERS file applied (configured with @dosadi)
- [ ] Dependabot enabled (file present, enable in settings)
- [x] Issue/PR templates created
- [ ] Labels created (see labels.yml)
- [ ] Repository topics added
- [ ] Social preview image uploaded
- [x] Security policy published
- [ ] Contributor workflows tested

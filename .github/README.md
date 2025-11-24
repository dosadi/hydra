# GitHub Integration Overview

This directory contains GitHub-specific configuration files for the Hydra project.

## Files in This Directory

### Issue & PR Templates
- **`ISSUE_TEMPLATE/bug_report.yml`** - Structured bug report template with component selection, reproduction steps, and environment details
- **`ISSUE_TEMPLATE/feature_request.yml`** - Feature request template with problem statement, proposed solution, and use cases
- **`ISSUE_TEMPLATE/config.yml`** - Issue template configuration with links to documentation
- **`pull_request_template.md`** - PR template with testing checklist, component marking, and reviewer guidance

### Automation & Security
- **`dependabot.yml`** - Automatic dependency updates for GitHub Actions and Python packages
- **`CODEOWNERS`** - Automatic reviewer assignment based on file paths
- **`SECURITY.md`** - Security vulnerability reporting policy and disclosure guidelines

### CI/CD
- **`workflows/ci.yml`** - Comprehensive CI workflow with Linux, QEMU, cocotb, and FreeBSD jobs

### Documentation & Configuration
- **`REPOSITORY_SETTINGS.md`** - Recommended GitHub repository settings (branch protection, required checks, etc.)
- **`labels.yml`** - Recommended label structure for issue/PR management
- **`README.md`** - This file

## Quick Start for Maintainers

### 1. Configure Repository Settings
Follow the checklist in `REPOSITORY_SETTINGS.md` to set up:
- Branch protection for `main`
- Required status checks
- Dependabot alerts
- Private vulnerability reporting

### 2. Apply Label Structure (Optional)
Use the label definitions in `labels.yml`:
```bash
# Using github-label-sync (install from npm)
npm install -g github-label-sync
github-label-sync --access-token $GITHUB_TOKEN owner/hydra .github/labels.yml
```

Or apply labels manually via GitHub UI.

### 3. Enable Branch Protection
In repository Settings → Branches:
- Add rule for `main` branch
- Require PR reviews (1 approval minimum)
- Require status checks: `linux`, `cocotb`, `freebsd-kmod`
- Block force pushes and deletions

### 4. Test Issue/PR Templates
- Create a test issue to verify templates render correctly
- Open a test PR to verify the PR template appears
- Ensure CODEOWNERS triggers review requests

## For Contributors

### Reporting Bugs
Use the bug report template - it will guide you through:
- Selecting the affected component
- Providing reproduction steps
- Including environment details
- Attaching logs or screenshots

### Requesting Features
Use the feature request template to describe:
- The problem you're trying to solve
- Your proposed solution
- Relevant use cases

### Opening Pull Requests
The PR template will remind you to:
- Run the test suite (`./scripts/hydra_dev_loop.sh`)
- Mark which components are affected
- Provide screenshots for visual changes
- Update documentation if needed

### Security Issues
**Do not open public issues for security vulnerabilities.**
Instead, follow the process in `SECURITY.md`:
- Use GitHub's private vulnerability reporting
- Or email maintainers directly with "SECURITY" in subject

## Maintenance Notes

### Dependabot PRs
Dependabot will automatically create PRs for:
- GitHub Actions updates (weekly on Monday)
- Python dependency updates (weekly on Monday)

Review and merge these PRs after CI passes.

### CI Workflow Updates
When modifying workflows:
- Test changes on a feature branch first
- Ensure required checks still pass
- Update `REPOSITORY_SETTINGS.md` if required checks change

### Label Management
Periodically review labels:
- Archive unused labels
- Add new labels for emerging patterns
- Update `labels.yml` to reflect changes

## Integration Status

✅ **Completed:**
- Issue templates (bug report, feature request)
- Pull request template
- CODEOWNERS file (configured with @dosadi)
- Security policy
- Dependabot configuration
- Label structure definition
- CI workflow consolidation (removed redundant workflows)
- Repository settings guide

⚠️ **Requires Manual Configuration:**
- Applying branch protection rules (requires admin access via GitHub UI)
- Creating labels via GitHub UI or sync tool
- Enabling required status checks in branch protection

## Resources

- [GitHub Documentation](https://docs.github.com)
- [Branch Protection Rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
- [CODEOWNERS](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners)
- [Dependabot](https://docs.github.com/en/code-security/dependabot)
- [Issue Templates](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/about-issue-and-pull-request-templates)

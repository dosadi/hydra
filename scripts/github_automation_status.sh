#!/bin/bash
# scripts/github_automation_status.sh
# Check status of GitHub automation features

set -euo pipefail

echo "=== GitHub Automation Status Dashboard ==="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

check_file() {
    local file="$1"
    local desc="$2"
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $desc: $file"
        return 0
    else
        echo -e "${RED}✗${NC} $desc: $file (MISSING)"
        return 1
    fi
}

check_dir() {
    local dir="$1"
    local desc="$2"
    if [ -d "$dir" ]; then
        echo -e "${GREEN}✓${NC} $desc: $dir/"
        return 0
    else
        echo -e "${RED}✗${NC} $desc: $dir/ (MISSING)"
        return 1
    fi
}

echo "=== Core GitHub Features ==="
check_file ".github/dependabot.yml" "Dependabot configuration"
check_dir ".github/workflows" "GitHub Actions workflows"
check_dir ".github/ISSUE_TEMPLATE" "Issue templates"
check_file ".github/pull_request_template.md" "Pull request template"
check_file ".github/labels.yml" "Label configuration"
check_file ".github/CODEOWNERS" "Code owners"
check_file ".github/SECURITY.md" "Security policy"

echo ""
echo "=== Workflows Status ==="
workflows=(
    "ci.yml:Main CI pipeline"
    "hygiene.yml:Code hygiene checks"
    "sim-smoke.yml:Simulation smoke tests"
    "doc_freshen.yml:Documentation auto-freshening"
    "windows_build.yml:Windows build automation"
    "axi_wrap_ci.yml:AXI wrap CI tests"
    "codeql.yml:Security scanning (CodeQL)"
    "dependency-review.yml:Dependency security review"
    "performance.yml:Performance regression detection"
    "stale.yml:Stale issue/PR management"
    "auto-label.yml:Automatic labeling"
    "release.yml:Release automation"
    "coverage.yml:Code coverage analysis"
)

missing_workflows=0
for workflow in "${workflows[@]}"; do
    file="${workflow%%:*}"
    desc="${workflow#*:}"
    if check_file ".github/workflows/$file" "$desc"; then
        # Check if workflow is properly configured
        if grep -q "name:" ".github/workflows/$file" 2>/dev/null; then
            echo -e "  ${BLUE}→${NC} Workflow configured"
        else
            echo -e "  ${YELLOW}⚠${NC} Workflow may need configuration"
        fi
    else
        ((missing_workflows++))
    fi
done

echo ""
echo "=== Automation Coverage ==="
total_features=13
configured_features=$((total_features - missing_workflows))
coverage=$((configured_features * 100 / total_features))

if [ $coverage -ge 90 ]; then
    color=$GREEN
elif [ $coverage -ge 70 ]; then
    color=$YELLOW
else
    color=$RED
fi

echo -e "Coverage: ${color}$configured_features/$total_features ($coverage%)${NC}"

echo ""
echo "=== Recommendations ==="

if [ $missing_workflows -gt 0 ]; then
    echo -e "${YELLOW}Missing workflows that could be added:${NC}"
    echo "  - CodeQL security scanning (codeql.yml)"
    echo "  - Dependency review for PRs (dependency-review.yml)"
    echo "  - Performance regression detection (performance.yml)"
    echo "  - Stale issue management (stale.yml)"
    echo "  - Auto-labeling (auto-label.yml)"
    echo "  - Release automation (release.yml)"
    echo "  - Code coverage (coverage.yml)"
    echo ""
fi

echo "=== Manual Setup Required ==="
echo "These features need manual GitHub repository configuration:"
echo "  - Branch protection rules (Settings → Branches)"
echo "  - Repository secrets for enhanced automation"
echo "  - GitHub Apps integration (optional)"
echo "  - Repository settings (Settings → General)"
echo ""

echo "=== Testing Automation ==="
echo "Run these commands to test automation:"
echo "  make automate-priority    # Test local automation"
echo "  ./scripts/automate_priority.sh --help  # See automation options"
echo ""

if [ $coverage -ge 80 ]; then
    echo -e "${GREEN}🎉 GitHub automation is well-configured!${NC}"
elif [ $coverage -ge 60 ]; then
    echo -e "${YELLOW}⚠️  GitHub automation is moderately configured${NC}"
else
    echo -e "${RED}❌ GitHub automation needs significant improvement${NC}"
fi
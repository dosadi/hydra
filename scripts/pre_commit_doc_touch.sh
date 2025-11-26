#!/bin/bash
# Pre-commit hook for doc touch system
# Checks if documentation is stale before allowing commit
#
# To install:
#   ln -s ../../scripts/pre_commit_doc_touch.sh .git/hooks/pre-commit
#
# To bypass:
#   git commit --no-verify

set -e

# Color codes
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo "🔍 Checking documentation freshness..."

# Check if we're modifying any docs
MODIFIED_DOCS=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(md|txt)$' || true)

if [ -z "$MODIFIED_DOCS" ]; then
    echo "✓ No documentation files modified, skipping freshness check"
    exit 0
fi

# Check if doc_touch.py exists
if [ ! -f "scripts/doc_touch.py" ]; then
    echo -e "${YELLOW}⚠ doc_touch.py not found, skipping freshness check${NC}"
    exit 0
fi

# Rebuild metadata to reflect current state
echo "Rebuilding doc metadata..."
python3 scripts/doc_touch.py --scan > /dev/null 2>&1 || {
    echo -e "${YELLOW}⚠ Failed to scan docs, proceeding anyway${NC}"
    exit 0
}

# Check for stale docs
if python3 scripts/doc_touch.py --check > /dev/null 2>&1; then
    echo -e "${GREEN}✓ All documentation is fresh${NC}"
    exit 0
else
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}⚠ WARNING: Stale documentation detected${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Show what's stale
    python3 scripts/doc_touch.py --check 2>&1 | head -20

    echo ""
    echo -e "${YELLOW}Recommended actions:${NC}"
    echo "  1. Auto-freshen Tier 1 docs: python3 scripts/doc_freshen.py --auto"
    echo "  2. Review stale docs:        python3 scripts/doc_touch.py --check"
    echo "  3. Bypass this check:        git commit --no-verify"
    echo ""

    # Don't fail the commit, just warn
    # To enforce freshness, uncomment the line below:
    # exit 1

    echo -e "${GREEN}Proceeding with commit (warning only)${NC}"
    exit 0
fi

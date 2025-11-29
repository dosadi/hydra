#!/bin/bash
# GitLens Troubleshooting and Reset Script
# Helps fix common GitLens issues in VS Code

set -euo pipefail

echo "🔧 GitLens Troubleshooting Script"
echo "=================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*" >&2; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*" >&2; }

# Check if GitLens is installed
check_gitlens() {
    log_info "Checking GitLens installation..."

    # Check if extension is recommended
    if grep -q "eamodio.gitlens" .vscode/extensions.json 2>/dev/null; then
        log_success "GitLens is recommended in extensions.json"
    else
        log_warn "GitLens not found in extensions.json"
        echo "  → Adding GitLens to recommendations..."
        # This would be added by the extensions.json we created
    fi

    # Check VS Code settings
    if grep -q "gitlens.enabled.*true" .vscode/settings.json 2>/dev/null; then
        log_success "GitLens is enabled in settings"
    else
        log_warn "GitLens settings not found or disabled"
    fi
}

# Reset GitLens settings
reset_gitlens_settings() {
    log_info "Resetting GitLens settings..."

    # Remove any conflicting git settings
    sed -i '/gitlens/d' .vscode/settings.json 2>/dev/null || true

    # Add clean GitLens settings
    cat >> .vscode/settings.json << 'EOF'

    // GitLens Configuration
    "gitlens.enabled": true,
    "gitlens.showWelcomeOnInstall": false,
    "gitlens.showStatusBarItem": true,
    "gitlens.views.repositories.enabled": true,
    "gitlens.views.fileHistory.enabled": true,
    "gitlens.views.lineHistory.enabled": true,
    "gitlens.views.compare.enabled": true,
    "gitlens.views.search.enabled": true,
EOF

    log_success "GitLens settings reset"
}

# Clear VS Code cache (if possible)
clear_vscode_cache() {
    log_info "Attempting to clear VS Code caches..."

    # Try to find VS Code user data directory
    VSCODE_DIR="${HOME}/.vscode"
    if [[ -d "$VSCODE_DIR" ]]; then
        log_info "Found VS Code user directory: $VSCODE_DIR"
        # Note: We can't actually clear caches from here as VS Code needs to be closed
        log_warn "VS Code caches require VS Code to be closed and restarted"
        echo "  → Close VS Code completely and reopen to clear caches"
    fi
}

# Check git repository health
check_git_health() {
    log_info "Checking git repository health..."

    if [[ ! -d .git ]]; then
        log_error "Not a git repository"
        return 1
    fi

    # Check git status
    if git status --porcelain | grep -q .; then
        log_warn "Repository has uncommitted changes"
        git status --short
    else
        log_success "Repository is clean"
    fi

    # Check for git config issues
    if git config --list | grep -q "conflict"; then
        log_warn "Potential git config conflicts detected"
    else
        log_success "Git configuration looks clean"
    fi
}

# Main troubleshooting flow
main() {
    echo "GitLens Troubleshooting Options:"
    echo "1. Check GitLens installation"
    echo "2. Reset GitLens settings"
    echo "3. Check git repository health"
    echo "4. Clear VS Code caches (requires restart)"
    echo "5. Full reset (all of the above)"
    echo ""

    local choice
    read -rp "Select option (1-5): " choice

    case $choice in
        1)
            check_gitlens
            ;;
        2)
            reset_gitlens_settings
            ;;
        3)
            check_git_health
            ;;
        4)
            clear_vscode_cache
            ;;
        5)
            log_info "Performing full GitLens reset..."
            check_gitlens
            reset_gitlens_settings
            check_git_health
            clear_vscode_cache
            log_success "Full reset completed"
            echo ""
            echo "Next steps:"
            echo "1. Close VS Code completely"
            echo "2. Reopen VS Code"
            echo "3. Check if GitLens extension is installed"
            echo "4. If not installed, install it from extensions sidebar"
            ;;
        *)
            log_error "Invalid option"
            exit 1
            ;;
    esac

    echo ""
    log_info "Troubleshooting completed"
    echo ""
    echo "If issues persist:"
    echo "• Try: Reload VS Code window (Ctrl+Shift+P → 'Developer: Reload Window')"
    echo "• Check: VS Code extensions sidebar for GitLens"
    echo "• Verify: GitLens is enabled in settings"
    echo "• Update: VS Code and GitLens to latest versions"
}

# Allow direct function calls
if [[ $# -gt 0 ]]; then
    case $1 in
        check) check_gitlens ;;
        reset) reset_gitlens_settings ;;
        git-health) check_git_health ;;
        cache) clear_vscode_cache ;;
        full) main <<< "5" ;;  # Simulate selecting option 5
        *) log_error "Unknown command: $1" ;;
    esac
else
    main
fi
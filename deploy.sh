#!/bin/bash
#
# Hydra CI/CD Integration - One-Step Deployment Script
# 
# This script deploys the complete CI/CD infrastructure to your Hydra repository.
# Run this from your Hydra project root directory.
#
# Usage: 
#   cd /path/to/hydra
#   bash <(curl -s https://raw.githubusercontent.com/.../deploy.sh)
#   
# Or if you have the integration package:
#   cd /path/to/hydra
#   /path/to/integration/deploy-to-hydra.sh
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Fancy output
print_header() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  $1"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

# Banner
clear
echo -e "${CYAN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════════════╗
║                                                                   ║
║   ██╗  ██╗██╗   ██╗██████╗ ██████╗  █████╗                      ║
║   ██║  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗██╔══██╗                     ║
║   ███████║ ╚████╔╝ ██║  ██║██████╔╝███████║                     ║
║   ██╔══██║  ╚██╔╝  ██║  ██║██╔══██╗██╔══██║                     ║
║   ██║  ██║   ██║   ██████╔╝██║  ██║██║  ██║                     ║
║   ╚═╝  ╚═╝   ╚═╝   ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝                     ║
║                                                                   ║
║           CI/CD Integration Deployment Script                    ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    print_error "This doesn't appear to be a git repository."
    print_info "Please run this script from your Hydra project root directory."
    exit 1
fi

print_success "Found git repository"

# Get the script directory (where integration files are)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
print_info "Integration files location: $SCRIPT_DIR"

# Check if integration files exist
if [ ! -f "$SCRIPT_DIR/.github-workflows-ci.yml" ]; then
    print_error "Cannot find integration files in $SCRIPT_DIR"
    print_info "Please ensure you've extracted the integration package."
    exit 1
fi

print_success "Found integration files"

# Confirm deployment
print_header "Deployment Confirmation"
echo ""
echo "This script will deploy CI/CD integration to:"
echo "  Repository: $(pwd)"
echo "  Integration: $SCRIPT_DIR"
echo ""
echo "The following will be created/modified:"
echo "  • .github/workflows/ci.yml"
echo "  • patches/qemu-hydra-device.patch"
echo "  • scripts/build.sh"
echo "  • scripts/guest-utils/hydra-test-suite"
echo "  • sim/verilator_socket_server.cpp"
echo "  • docs/INTEGRATION.md"
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Deployment cancelled"
    exit 0
fi

print_header "Step 1: Creating Directory Structure"

# Create directories
mkdir -p .github/workflows
print_success "Created .github/workflows/"

mkdir -p patches
print_success "Created patches/"

mkdir -p scripts/guest-utils
print_success "Created scripts/guest-utils/"

mkdir -p sim
print_success "Created sim/"

mkdir -p docs
print_success "Created docs/"

print_header "Step 2: Copying GitHub Actions Workflow"

cp "$SCRIPT_DIR/.github-workflows-ci.yml" .github/workflows/ci.yml
print_success "Installed GitHub Actions workflow"
print_info "Location: .github/workflows/ci.yml"

print_header "Step 3: Installing QEMU Patch"

cp "$SCRIPT_DIR/patches/qemu-hydra-device.patch" patches/
print_success "Installed QEMU device patch"
print_info "Location: patches/qemu-hydra-device.patch"

print_header "Step 4: Installing Build Automation"

cp "$SCRIPT_DIR/scripts/build.sh" scripts/
chmod +x scripts/build.sh
print_success "Installed build automation script"
print_info "Location: scripts/build.sh"

print_header "Step 5: Installing Test Suite"

cp "$SCRIPT_DIR/scripts/guest-utils/hydra-test-suite" scripts/guest-utils/
chmod +x scripts/guest-utils/hydra-test-suite
print_success "Installed TinyCore test suite"
print_info "Location: scripts/guest-utils/hydra-test-suite"

print_header "Step 6: Installing Verilator Backend"

cp "$SCRIPT_DIR/sim/verilator_socket_server.cpp" sim/
print_success "Installed Verilator socket server"
print_info "Location: sim/verilator_socket_server.cpp"

print_header "Step 7: Installing Documentation"

cp "$SCRIPT_DIR/INTEGRATION.md" docs/
print_success "Installed technical documentation"
print_info "Location: docs/INTEGRATION.md"

if [ -f "$SCRIPT_DIR/DEPLOYMENT.md" ]; then
    cp "$SCRIPT_DIR/DEPLOYMENT.md" docs/
    print_success "Installed deployment guide"
    print_info "Location: docs/DEPLOYMENT.md"
fi

if [ -f "$SCRIPT_DIR/QUICKREF.txt" ]; then
    cp "$SCRIPT_DIR/QUICKREF.txt" docs/
    print_success "Installed quick reference"
    print_info "Location: docs/QUICKREF.txt"
fi

print_header "Step 8: Verifying RTL Interface"

if [ -f "rtl/hydra_top.sv" ]; then
    print_success "Found rtl/hydra_top.sv"
    
    # Check for required ports
    has_clk=$(grep -c "input.*clk" rtl/hydra_top.sv || echo 0)
    has_rst=$(grep -c "input.*rst" rtl/hydra_top.sv || echo 0)
    has_cam=$(grep -c "cam_pos\|cam_dir" rtl/hydra_top.sv || echo 0)
    
    if [ "$has_clk" -gt 0 ] && [ "$has_rst" -gt 0 ]; then
        print_success "Basic clock and reset found"
    else
        print_warning "Could not verify clock/reset signals"
    fi
    
    if [ "$has_cam" -gt 0 ]; then
        print_success "Camera interface signals found"
    else
        print_warning "Camera interface may need adjustment"
        print_info "Expected ports: cam_pos_x, cam_pos_y, cam_pos_z, cam_dir_x, cam_dir_y, cam_dir_z"
        print_info "See docs/INTEGRATION.md for complete interface specification"
    fi
else
    print_warning "rtl/hydra_top.sv not found"
    print_info "You may need to create a top-level wrapper"
    print_info "See docs/INTEGRATION.md for required interface"
fi

print_header "Step 9: Git Status"

echo ""
echo "New files to be committed:"
git status --short | grep -E "^\?\?" || echo "  (no untracked files)"
echo ""
echo "Modified files:"
git status --short | grep -E "^.M" || echo "  (no modified files)"
echo ""

read -p "Add files to git? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    git add .github/workflows/ci.yml
    git add patches/
    git add scripts/
    git add sim/
    git add docs/
    print_success "Files added to git"
else
    print_info "Skipped git add. Run manually: git add .github patches scripts sim docs"
fi

print_header "Deployment Complete!"

echo ""
print_success "CI/CD integration successfully deployed!"
echo ""
echo -e "${CYAN}Next Steps:${NC}"
echo ""
echo "1. Review the changes:"
echo "   git status"
echo "   git diff --cached"
echo ""
echo "2. Test locally (recommended):"
echo "   ./scripts/build.sh all"
echo "   ./scripts/build.sh test"
echo ""
echo "3. Commit and push:"
echo "   git commit -m \"Add CI/CD integration infrastructure\""
echo "   git push origin main"
echo ""
echo "4. Monitor the CI pipeline:"
echo "   • Go to GitHub → Actions tab"
echo "   • Watch the first build (will take ~60 min)"
echo "   • Subsequent builds will be ~25 min (cached)"
echo ""
echo -e "${CYAN}Documentation:${NC}"
echo "   • Quick reference:    cat docs/QUICKREF.txt"
echo "   • Technical details:  cat docs/INTEGRATION.md"
echo "   • Deployment guide:   cat docs/DEPLOYMENT.md"
echo ""
echo -e "${CYAN}Local Testing:${NC}"
echo "   ./scripts/build.sh --help    # See all commands"
echo "   ./scripts/build.sh all       # Build everything"
echo "   ./scripts/build.sh test      # Run integration test"
echo ""
echo -e "${GREEN}🎉 Your Hydra project now has professional CI/CD automation! 🎉${NC}"
echo ""
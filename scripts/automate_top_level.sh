#!/usr/bin/env bash
# Top-level automation orchestrator for Hydra project
# Runs comprehensive checks, builds, tests, and maintenance tasks

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}/.."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Main automation function
run_full_automation() {
    log_info "Starting Hydra full automation suite..."

    # 1. Environment and dependency checks
    log_info "Checking environment and dependencies..."
    make env-probe
    make verilator-check
    make files

    # 2. Code quality checks
    log_info "Running code quality checks..."
    make lint
    make docs-only
    make license-check

    # 3. Build and test
    log_info "Building and testing..."
    make sim
    make test
    make sdk-setup

    # 4. Priority sector automation
    log_info "Running priority sector automation..."
    ./scripts/automate_priority.sh

    # 5. Touch system checks
    log_info "Checking touch system freshness..."
    make touch-check-all

    # 6. Additional validation
    log_info "Running additional validation..."
    make todo-unique
    ./scripts/todo_sweep.py

    # 7. External chunk processing
    log_info "Processing external chunks..."
    python3 scripts/external_chunk_handler.py --process-all || log_warning "Chunk processing had issues"

    # 8. Optional: RTL tests if iverilog available
    if command_exists iverilog && command_exists vvp; then
        log_info "Running RTL tests..."
        ./sim/tests/run_rtl_tests.sh
    else
        log_warning "iverilog/vvp not found, skipping RTL tests"
    fi

    log_success "Full automation suite completed successfully!"
}

# Quick automation (subset for faster feedback)
run_quick_automation() {
    log_info "Starting Hydra quick automation..."

    make lint
    make docs-only
    make files
    make todo-unique
    ./scripts/automate_priority.sh --skip-bench --skip-security --skip-integration
    make touch-check-all

    # Quick chunk processing
    log_info "Quick chunk processing check..."
    python3 scripts/external_chunk_handler.py --status || log_warning "Chunk status check failed"

    log_success "Quick automation completed!"
}

# Agent coordination checks
run_agent_coordination() {
    log_info "Running agent coordination checks..."

    # Check agent integration bridge
    if [[ -f "docs/agent_integration_bridge.md" ]]; then
        log_info "Agent integration bridge exists"
    else
        log_warning "Agent integration bridge missing"
    fi

    # Run TODO sweep for coordination
    ./scripts/todo_sweep.py

    # Check for active agent sessions
    if [[ -f "docs/TODO_SESSION_CONTINUATION_2025_11_25.md" ]]; then
        log_info "Active session continuation document found"
    fi

    log_success "Agent coordination checks completed!"
}

# Help function
show_help() {
    cat << EOF
Hydra Top-Level Automation Orchestrator

USAGE:
    $0 [OPTIONS] [COMMAND]

COMMANDS:
    full        Run complete automation suite (default)
    quick       Run quick automation subset
    agents      Run agent coordination checks
    help        Show this help message

OPTIONS:
    --dry-run   Show what would be executed without running
    --verbose   Enable verbose output
    --help      Show this help message

EXAMPLES:
    $0 full          # Run complete automation
    $0 quick         # Run quick checks
    $0 agents        # Check agent coordination
    $0 --dry-run     # Show execution plan

This script orchestrates:
- Environment validation
- Code quality checks
- Build and test execution
- Priority sector automation
- Touch system freshness
- Agent coordination (when applicable)
EOF
}

# Main script logic
DRY_RUN=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        full|quick|agents|help)
            COMMAND="$1"
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Default command
COMMAND="${COMMAND:-full}"

# Dry run setup
if [[ "$DRY_RUN" == true ]]; then
    log_info "DRY RUN MODE - Commands will be shown but not executed"
    # Override make and script calls to echo instead
    make() {
        echo "make $*"
    }
    ./scripts/() {
        echo "./scripts/$*"
    }
fi

# Execute command
case "$COMMAND" in
    full)
        run_full_automation
        ;;
    quick)
        run_quick_automation
        ;;
    agents)
        run_agent_coordination
        ;;
    help)
        show_help
        ;;
    *)
        log_error "Unknown command: $COMMAND"
        show_help
        exit 1
        ;;
esac
#!/bin/bash
# scripts/automate_priority.sh
# Comprehensive automation wrapper for Hydra priority sectors
# Runs build, test, lint, docs, and benchmark automation

set -euo pipefail

echo "=== Hydra Priority Sector Automation ==="
echo "This script automates the key priority areas of the Hydra project:"
echo "- Build automation (sim, SDK, drivers)"
echo "- Testing automation (frame regression, RTL benches)"
echo "- Code quality automation (lint, format, checks)"
echo "- Documentation automation (freshening, touch system)"
echo "- Benchmarking automation"
echo "- Security automation (secrets, permissions, vulnerabilities)"
echo "- Integration automation (backends, Docker, CMake)"
echo ""

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[AUTO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to run a command and report status
run_cmd() {
    local desc="$1"
    shift
    log "Running: $desc"
    if "$@"; then
        log "✓ $desc completed successfully"
        return 0
    else
        error "✗ $desc failed"
        return 1
    fi
}

# Check if tools are available
check_tools() {
    log "Checking required tools..."
    local missing=()

    command -v make >/dev/null 2>&1 || missing+=("make")
    command -v gcc >/dev/null 2>&1 || missing+=("gcc")
    command -v verilator >/dev/null 2>&1 || missing+=("verilator")
    command -v python3 >/dev/null 2>&1 || missing+=("python3")

    if [ ${#missing[@]} -ne 0 ]; then
        error "Missing required tools: ${missing[*]}"
        exit 1
    fi

    log "✓ All required tools found"
}

# Build sector automation
build_sector() {
    log "=== BUILD SECTOR AUTOMATION ==="

    # Sim build
    run_cmd "Building Verilator sim" make sim

    # SDK setup
    if [ -f scripts/setup_sdk.sh ]; then
        run_cmd "Setting up SDK tools" ./scripts/setup_sdk.sh || warn "SDK setup had issues (may be expected)"
    fi

    # Optional driver builds
    if [ -f drivers/linux/Makefile ]; then
        run_cmd "Building Linux driver" make driver-linux || warn "Linux driver build failed (may require kernel headers)"
    fi

    log "✓ Build sector automation complete"
}

# Test sector automation
test_sector() {
    log "=== TEST SECTOR AUTOMATION ==="

    # Frame regression test
    run_cmd "Running frame regression test" make test

    # Pixel test
    run_cmd "Running pixel96 unit test" make pixel-test

    # Optional RTL benches
    if command -v iverilog >/dev/null 2>&1 && [ -f sim/tests/run_rtl_tests.sh ]; then
        run_cmd "Running RTL benches" timeout 300s sim/tests/run_rtl_tests.sh || warn "RTL benches failed or timed out"
    fi

    log "✓ Test sector automation complete"
}

# Code quality sector automation
quality_sector() {
    log "=== CODE QUALITY SECTOR AUTOMATION ==="

    # Lint checks
    run_cmd "Running linters" make lint || warn "Some lint checks failed"

    # License check
    run_cmd "Checking license headers" make license-check

    # Verilator version check
    run_cmd "Checking Verilator version" make verilator-check

    # Required files check
    run_cmd "Verifying required files" make files

    # TODO uniqueness
    run_cmd "Checking TODO uniqueness" make todo-unique

    log "✓ Code quality sector automation complete"
}

# Documentation sector automation
docs_sector() {
    log "=== DOCUMENTATION SECTOR AUTOMATION ==="

    # Docs lint
    run_cmd "Linting documentation" make docs

    # Spellcheck
    run_cmd "Spellchecking docs" make spellcheck

    # Touch system checks
    run_cmd "Checking documentation freshness" make doc-check

    # Build touch checks
    run_cmd "Checking build freshness" make build-check

    log "✓ Documentation sector automation complete"
}

# Benchmark sector automation
benchmark_sector() {
    log "=== BENCHMARK SECTOR AUTOMATION ==="

    # Quick benchmark
    run_cmd "Running quick benchmark" make bench

    # Render benchmark
    if [ -f scripts/render_benchmark.sh ]; then
        run_cmd "Running render benchmark" ./scripts/render_benchmark.sh
    fi

    log "✓ Benchmark sector automation complete"
}

# Security sector automation
security_sector() {
    log "=== SECURITY SECTOR AUTOMATION ==="

    # Check for secrets or sensitive data
    if command -v git >/dev/null 2>&1; then
        run_cmd "Checking for accidentally committed secrets" git log --all --full-history -- "*.key" "*.pem" "*.p12" "*.pfx" || warn "Secret check completed with warnings"
    fi

    # Check file permissions
    run_cmd "Checking file permissions" find . -type f \( -name "*.sh" -o -name "*.py" \) -exec test -x {} \; -print | wc -l || warn "Some scripts may not be executable"

    # Dependency vulnerability check (if tools available)
    if command -v pip-audit >/dev/null 2>&1 && [ -f requirements.txt ]; then
        run_cmd "Checking Python dependencies for vulnerabilities" pip-audit --requirement requirements.txt || warn "Dependency audit completed with warnings"
    fi

    log "✓ Security sector automation complete"
}

# Integration sector automation
integration_sector() {
    log "=== INTEGRATION SECTOR AUTOMATION ==="

    # Cross-platform compatibility check
    if [ -f scripts/check_backends.sh ]; then
        run_cmd "Checking backend compatibility" ./scripts/check_backends.sh || warn "Backend check had issues"
    fi

    # Docker build test
    if [ -f docker/Dockerfile ]; then
        run_cmd "Testing Docker build" docker build --no-cache --pull -t hydra-test docker/ || warn "Docker build test failed"
    fi

    # CMake preset validation
    if command -v cmake >/dev/null 2>&1; then
        run_cmd "Validating CMake presets" cmake --list-presets || warn "CMake preset validation had issues"
    fi

    # External chunk processing
    if [ -f scripts/external_chunk_handler.py ]; then
        run_cmd "Processing external chunks" python3 scripts/external_chunk_handler.py --process-all || warn "Chunk processing had issues"
    fi

    log "✓ Integration sector automation complete"
}

# Main automation flow
main() {
    local sectors=()
    local skip_build=false
    local skip_test=false
    local skip_quality=false
    local skip_docs=false
    local skip_bench=false
    local skip_security=false
    local skip_integration=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-build) skip_build=true ;;
            --skip-test) skip_test=true ;;
            --skip-quality) skip_quality=true ;;
            --skip-docs) skip_docs=true ;;
            --skip-bench) skip_bench=true ;;
            --skip-security) skip_security=true ;;
            --skip-integration) skip_integration=true ;;
            --help)
                echo "Usage: $0 [options]"
                echo "Options:"
                echo "  --skip-build       Skip build automation"
                echo "  --skip-test        Skip test automation"
                echo "  --skip-quality     Skip code quality automation"
                echo "  --skip-docs        Skip documentation automation"
                echo "  --skip-bench       Skip benchmark automation"
                echo "  --skip-security    Skip security automation"
                echo "  --skip-integration Skip integration automation"
                echo "  --help             Show this help"
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                exit 1
                ;;
        esac
        shift
    done

    check_tools

    if [ "$skip_build" = false ]; then
        build_sector
        sectors+=("build")
    fi

    if [ "$skip_test" = false ]; then
        test_sector
        sectors+=("test")
    fi

    if [ "$skip_quality" = false ]; then
        quality_sector
        sectors+=("quality")
    fi

    if [ "$skip_docs" = false ]; then
        docs_sector
        sectors+=("docs")
    fi

    if [ "$skip_bench" = false ]; then
        benchmark_sector
        sectors+=("benchmark")
    fi

    if [ "$skip_security" = false ]; then
        security_sector
        sectors+=("security")
    fi

    if [ "$skip_integration" = false ]; then
        integration_sector
        sectors+=("integration")
    fi

    echo ""
    log "=== AUTOMATION COMPLETE ==="
    log "Sectors automated: ${sectors[*]}"
    log "Priority sectors wrapped and executed successfully"
}

# Run main function
main "$@"
#!/bin/bash

# Hydra Open Source Coverage Tools Setup
# Installs and configures open source coverage tools for UVM verification

set -e

echo "=== Setting up Open Source Coverage Tools for Hydra UVM ==="

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install LCOV (Linux Test Project coverage tool)
install_lcov() {
    echo "Installing LCOV..."

    if command_exists apt-get; then
        sudo apt-get update
        sudo apt-get install -y lcov
    elif command_exists yum; then
        sudo yum install -y lcov
    elif command_exists dnf; then
        sudo dnf install -y lcov
    elif command_exists brew; then
        brew install lcov
    else
        echo "Package manager not found. Please install LCOV manually."
        return 1
    fi

    echo "LCOV installed successfully"
}

# Install gcovr (alternative coverage tool)
install_gcovr() {
    echo "Installing gcovr..."

    if command_exists pip3; then
        pip3 install gcovr
    elif command_exists pip; then
        pip install gcovr
    else
        echo "pip not found. Please install gcovr manually."
        return 1
    fi

    echo "gcovr installed successfully"
}

# Install Verilator with coverage support
install_verilator_coverage() {
    echo "Installing Verilator with coverage support..."

    if command_exists apt-get; then
        sudo apt-get install -y verilator
    elif command_exists brew; then
        brew install verilator
    else
        echo "Please install Verilator manually from: https://www.veripool.org/verilator/"
        return 1
    fi

    echo "Verilator installed successfully"
}

# Check and install tools
echo "Checking for required coverage tools..."

TOOLS_INSTALLED=0

if ! command_exists lcov; then
    install_lcov && ((TOOLS_INSTALLED++))
else
    echo "LCOV already installed"
fi

if ! command_exists gcovr; then
    install_gcovr && ((TOOLS_INSTALLED++))
else
    echo "gcovr already installed"
fi

if ! command_exists verilator; then
    install_verilator_coverage && ((TOOLS_INSTALLED++))
else
    echo "Verilator already installed"
fi

# Verify installations
echo ""
echo "Verifying tool installations..."
echo "LCOV version: $(lcov --version 2>/dev/null | head -1 || echo 'Not found')"
echo "gcovr version: $(gcovr --version 2>/dev/null | head -1 || echo 'Not found')"
echo "Verilator version: $(verilator --version 2>/dev/null || echo 'Not found')"

# Create coverage workflow script
cat > coverage_workflow.sh << 'EOF'
#!/bin/bash

# Hydra Coverage Analysis Workflow
# Uses open source tools to analyze UVM verification coverage

echo "=== Hydra Coverage Analysis Workflow ==="

# Step 1: Run UVM tests with coverage
echo "Step 1: Running UVM tests with coverage collection..."
make test_integration COVERAGE=1

# Step 2: Collect coverage data
echo "Step 2: Collecting coverage data..."
if [ -f "coverage.dat" ]; then
    echo "Found coverage data file"
else
    echo "No coverage data found - running analysis script..."
    ./analyze_coverage.sh
fi

# Step 3: Generate LCOV reports
echo "Step 3: Generating LCOV coverage reports..."
lcov --capture --directory . --output-file coverage.info
lcov --remove coverage.info '*/testbench/*' '*/uvm_pkg/*' -o coverage_filtered.info
genhtml coverage_filtered.info --output-directory coverage_html

# Step 4: Generate gcovr reports
echo "Step 4: Generating gcovr coverage reports..."
gcovr --html --html-details -o coverage_gcovr.html
gcovr --json -o coverage_gcovr.json

# Step 5: Generate summary
echo "Step 5: Generating coverage summary..."
echo "Coverage Summary:" > coverage_summary.txt
echo "=================" >> coverage_summary.txt
echo "Generated: $(date)" >> coverage_summary.txt
echo "" >> coverage_summary.txt

if [ -f "coverage_metrics.json" ]; then
    echo "UVM Coverage Metrics:" >> coverage_summary.txt
    cat coverage_metrics.json >> coverage_summary.txt
    echo "" >> coverage_summary.txt
fi

echo "Coverage reports generated:"
echo "  - HTML: coverage_html/index.html"
echo "  - gcovr HTML: coverage_gcovr.html"
echo "  - JSON: coverage_gcovr.json"
echo "  - Summary: coverage_summary.txt"

echo "=== Coverage Analysis Complete ==="
EOF

chmod +x coverage_workflow.sh

echo ""
echo "=== Setup Complete ==="
echo "Installed $TOOLS_INSTALLED new tools"
echo ""
echo "Available coverage tools:"
echo "  - lcov/genhtml: Line and branch coverage analysis"
echo "  - gcovr: Alternative coverage reporting"
echo "  - verilator: SystemVerilog simulation with coverage"
echo ""
echo "To run full coverage analysis:"
echo "  ./coverage_workflow.sh"
echo ""
echo "Coverage configuration: coverage_config.ini"
echo "Analysis script: analyze_coverage.sh"
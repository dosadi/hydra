#!/bin/bash
# ============================================================================
# Hydra Packaging and Distribution
# Create release packages and distribution artifacts
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "========================================"
echo "   HYDRA PACKAGING & DISTRIBUTION"
echo "========================================"

OUTPUT_DIR="$SCRIPT_DIR/releases"
mkdir -p "$OUTPUT_DIR"

# Get version information
VERSION=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.7-dev")
COMMIT=$(git rev-parse --short HEAD)
DATE=$(date +%Y%m%d)

PACKAGE_NAME="hydra-${VERSION}-${DATE}-${COMMIT}"
PACKAGE_DIR="$OUTPUT_DIR/$PACKAGE_NAME"

echo ""
echo "Creating release package: $PACKAGE_NAME"
echo "--------------------------------------"

# Create package directory
mkdir -p "$PACKAGE_DIR"

# Copy core components
echo "Copying core components..."

# RTL source
mkdir -p "$PACKAGE_DIR/rtl"
cp -r "$PROJECT_ROOT/rtl"/* "$PACKAGE_DIR/rtl/" 2>/dev/null || true

# Simulation
mkdir -p "$PACKAGE_DIR/sim"
cp -r "$PROJECT_ROOT/sim"/* "$PACKAGE_DIR/sim/" 2>/dev/null || true

# Drivers
mkdir -p "$PACKAGE_DIR/drivers"
cp -r "$PROJECT_ROOT/drivers"/* "$PACKAGE_DIR/drivers/" 2>/dev/null || true

# Scripts (selected)
mkdir -p "$PACKAGE_DIR/scripts"
cp "$PROJECT_ROOT/scripts/setup_sdk.sh" "$PACKAGE_DIR/scripts/"
cp "$PROJECT_ROOT/scripts/env_probe.sh" "$PACKAGE_DIR/scripts/"
cp "$PROJECT_ROOT/scripts/check_frame.py" "$PACKAGE_DIR/scripts/"

# Documentation
mkdir -p "$PACKAGE_DIR/docs"
cp -r "$PROJECT_ROOT/docs"/* "$PACKAGE_DIR/docs/" 2>/dev/null || true

# Constraints
mkdir -p "$PACKAGE_DIR/constraints"
cp -r "$PROJECT_ROOT/constraints"/* "$PACKAGE_DIR/constraints/" 2>/dev/null || true

# Verification (UVM framework)
mkdir -p "$PACKAGE_DIR/verification"
cp -r "$PROJECT_ROOT/verification"/* "$PACKAGE_DIR/verification/" 2>/dev/null || true

# Synthesis infrastructure
mkdir -p "$PACKAGE_DIR/synthesis"
cp -r "$PROJECT_ROOT/synthesis"/* "$PACKAGE_DIR/synthesis/" 2>/dev/null || true

# Create package metadata
cat > "$PACKAGE_DIR/package_info.txt" << EOF
Hydra FPGA Accelerator Package
===============================

Version: $VERSION
Commit: $COMMIT
Date: $DATE

Package Contents:
- rtl/: SystemVerilog RTL source files
- sim/: Verilator simulation with SDL viewer
- drivers/: Linux/BSD driver implementations
- scripts/: Setup and utility scripts
- docs/: Documentation and guides
- constraints/: FPGA synthesis constraints
- verification/: UVM verification framework
- synthesis/: FPGA synthesis flows

Build Instructions:
1. cd sim && make          # Build simulation
2. cd drivers/libhydra && make  # Build SDK
3. make synth-vivado       # Run Vivado synthesis (requires Vivado)
4. make uvm-test          # Run UVM tests (requires simulator)

For detailed instructions, see docs/ and README.md

Requirements:
- Verilator 5.x+
- SDL2 development libraries
- GCC 9.0+
- Python 3.8+ (for scripts)
- FPGA tools (optional): Vivado, Quartus, Yosys

License: See LICENSE file
EOF

# Copy license and readme
cp "$PROJECT_ROOT/LICENSE" "$PACKAGE_DIR/" 2>/dev/null || true
cp "$PROJECT_ROOT/README.md" "$PACKAGE_DIR/" 2>/dev/null || true
cp "$PROJECT_ROOT/Makefile" "$PACKAGE_DIR/" 2>/dev/null || true

# Create compressed archives
echo ""
echo "Creating distribution archives..."
echo "---------------------------------"

cd "$OUTPUT_DIR"

# Create tar.gz archive
echo "Creating tar.gz archive..."
tar -czf "${PACKAGE_NAME}.tar.gz" "$PACKAGE_NAME"

# Create zip archive
echo "Creating zip archive..."
zip -r "${PACKAGE_NAME}.zip" "$PACKAGE_NAME"

# Create checksums
echo "Generating checksums..."
sha256sum "${PACKAGE_NAME}.tar.gz" > "${PACKAGE_NAME}.tar.gz.sha256"
sha256sum "${PACKAGE_NAME}.zip" > "${PACKAGE_NAME}.zip.sha256"

# Create release notes
cat > "${PACKAGE_NAME}_release_notes.md" << EOF
# Hydra ${VERSION} Release Notes

## Release Information
- **Version**: $VERSION
- **Date**: $(date)
- **Commit**: $COMMIT

## What's New in This Release

### Major Features
- Complete UVM verification framework with constrained random testing
- Multi-tool FPGA synthesis support (Vivado, Quartus, Yosys)
- Enhanced simulation with SDL-based 3D viewer
- Comprehensive driver support (Linux PCIe, BSD stubs)
- Advanced documentation and automation infrastructure

### Verification & Testing
- UVM testbench with agents, scoreboards, and coverage
- Performance profiling sequences
- Constrained random stimulus generation
- Formal verification support (SymbiYosys)

### Synthesis & Implementation
- Vivado synthesis flow with timing closure
- Quartus synthesis for Intel FPGAs
- Yosys open-source synthesis
- Comprehensive timing constraints
- Power and area analysis

### Infrastructure
- Automated CI/CD pipelines
- Code quality analysis and linting
- Performance benchmarking suite
- Security analysis framework
- Comprehensive documentation

## System Requirements

### Minimum Requirements
- Linux/macOS/Windows
- GCC 9.0+ or Clang 10.0+
- Python 3.8+
- 4GB RAM
- 2GB disk space

### Recommended Requirements
- Ubuntu 20.04+ or RHEL 8+
- GCC 11.0+ or Clang 14.0+
- Python 3.9+
- 8GB RAM
- 10GB disk space
- FPGA development board (for hardware testing)

## Installation

### From Source
\`\`\`bash
# Extract package
tar -xzf ${PACKAGE_NAME}.tar.gz
cd $PACKAGE_NAME

# Build simulation
make sim

# Build SDK
make sdk-setup

# Run tests
make test
\`\`\`

### FPGA Synthesis (Optional)
\`\`\`bash
# Vivado synthesis
make synth-vivado

# Quartus synthesis
make synth-quartus

# Yosys synthesis
make synth-yosys
\`\`\`

## Known Issues
- UVM tests require commercial simulator (Questa/ModelSim)
- FPGA synthesis requires vendor tools
- Some advanced features require additional dependencies

## Support
- Documentation: docs/ directory
- Issues: GitHub issue tracker
- Discussions: GitHub discussions

## License
This release is licensed under the terms in LICENSE.
EOF

# Clean up
echo ""
echo "Cleaning up temporary files..."
rm -rf "$PACKAGE_DIR"

echo ""
echo "Packaging completed successfully!"
echo "Release artifacts:"
echo "  - ${PACKAGE_NAME}.tar.gz"
echo "  - ${PACKAGE_NAME}.zip"
echo "  - ${PACKAGE_NAME}_release_notes.md"
echo ""
echo "Checksums:"
echo "  $(cat ${PACKAGE_NAME}.tar.gz.sha256)"
echo "  $(cat ${PACKAGE_NAME}.zip.sha256)"
echo ""
echo "========================================"
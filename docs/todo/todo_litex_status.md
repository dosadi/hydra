# LiteX Integration Status & Immediate Actions

**Created:** 2025-11-29
**Status:** BLOCKED - Prototype Phase
**Priority:** P0 (Hardware Track)
**Owner:** IP Integration Team

---

## Current Status Assessment

**LiteX integration remains in PROTOTYPE phase with ZERO actual integration:**

### ✅ What Exists (Planning/Documentation)
- Comprehensive 50-item roadmap in `docs/todo/todo_ip_integration.md`
- LiteX sources vendored in `third_party/litex/`
- Prototype scripts: `hydra_litex_nexysvideo.py`, `hydra_litex_shell.py`
- Stub RTL files: `rtl/litex/litex_pcie_bridge.sv`, `rtl/litex/litex_dma_engine.sv`
- CI linting: `scripts/test_litex_stubs.sh` runs in Windows CI

### ❌ What Does NOT Exist (Actual Integration)
- No LiteX IP cores in current builds or simulation
- No LiteX-generated hardware in synthesis
- No actual PCIe/DMA/HDMI using LiteX cores
- No LiteX build process integrated into main build system
- Current simulation uses AXI stubs, not LiteX IP

---

## Immediate Blockers (Why We're Stuck)

### 1. Missing IP Fetch Process
- `scripts/fetch_ip.sh` mentioned in roadmap but may not exist
- No automated process to get LitePCIe/LiteDRAM/LiteVideo sources
- Manual dependency management required

### 2. No Build Integration
- LiteX build scripts not integrated into main `Makefile`
- No CMake integration for LiteX cores
- No synthesis flow using LiteX-generated RTL

### 3. External Dependencies
- Requires `litex-boards` package (not in repo)
- Python environment setup for LiteX/Migen
- FPGA board selection and constraints

### 4. Prototype vs Production Gap
- Prototype scripts exist but untested
- No validation that prototypes actually work
- No hardware testing infrastructure

---

## Immediate Action Items (Next 1-2 Weeks)

### P0-CRITICAL: Unblock Basic Integration

**TODO [P0]:** Create working IP fetch process
- **Effort:** 2-3 days
- **Deliverable:** `scripts/fetch_litex_ip.sh` that downloads and sets up:
  - LitePCIe for target FPGA (Artix-7 PCIe Gen2 x4)
  - LiteDRAM controller for DDR3
  - LiteVideo TMDS encoder
- **Validation:** All IP sources available in `third_party/`
- **Owner:** Build Team

**TODO [P0]:** Integrate LiteX into build system
- **Effort:** 3-4 days
- **Deliverable:** Add LiteX build targets to `Makefile`:
  - `make litex-pcie` - Generate PCIe wrapper
  - `make litex-soc` - Build complete SoC
  - `make litex-synth` - Synthesize for FPGA
- **Dependencies:** IP fetch process working
- **Validation:** Can build LiteX cores from command line

**TODO [P0]:** Validate prototype scripts
- **Effort:** 2-3 days
- **Deliverable:** Test `hydra_litex_nexysvideo.py` and `hydra_litex_shell.py`:
  - Fix any import errors
  - Verify LiteX API compatibility
  - Generate test RTL output
- **Dependencies:** LiteX environment set up
- **Validation:** Prototype scripts run without errors

**TODO [P0]:** Set up FPGA board integration
- **Effort:** 2-3 days
- **Deliverable:** Nexys Video board support:
  - Install `litex-boards` dependency
  - Create board-specific constraints
  - Test basic LiteX board bring-up
- **Dependencies:** LiteX build system working
- **Validation:** Can build "Hello World" LiteX design for Nexys Video

### P1-HIGH: First Working Integration

**TODO [P1]:** Implement PCIe BAR0 access via LitePCIe
- **Effort:** 5 days
- **Deliverable:** Replace AXI stub with real LitePCIe core:
  - Generate LitePCIe wrapper for Artix-7
  - Wire BAR0 to `voxel_axil_csr.sv`
  - Test CSR read/write from host
- **Dependencies:** IP fetch + build integration
- **Validation:** Host can access Hydra CSRs via PCIe

**TODO [P1]:** Add LiteX SoC builder integration
- **Effort:** 4 days
- **Deliverable:** Automated top-level generation:
  - Integrate `HydraCore` from `hydra_litex_shell.py`
  - Generate complete SoC with PCIe + DRAM + HDMI
  - Replace manual RTL integration
- **Dependencies:** Prototype scripts validated
- **Validation:** LiteX generates working top-level RTL

---

## Success Criteria (1 Month Horizon)

### Minimum Viable Integration
- [ ] `make litex-pcie` generates working PCIe endpoint
- [ ] Host can read/write CSRs through LitePCIe BAR0
- [ ] LiteX SoC builder creates valid top-level
- [ ] FPGA synthesis completes without errors
- [ ] Basic PCIe enumeration works on hardware

### Validation Milestones
- [ ] All prototype scripts run successfully
- [ ] LiteX IP cores integrate without build errors
- [ ] Simulation works with LiteX cores (not just stubs)
- [ ] Hardware bring-up possible with LiteX-generated design

---

## Risk Mitigation

### Fallback Plans
- **Continue with AXI stubs** for 0.0.7 software release
- **Manual IP integration** if LiteX automation fails
- **Alternative IP sources** if LiteX cores have issues

### Dependencies to Monitor
- **LiteX project health** - Check for breaking changes
- **litex-boards availability** - May need local fork
- **FPGA tool compatibility** - Vivado version support

---

## Next Steps After Unblocking

1. **Week 1:** Complete P0 items (IP fetch, build integration, prototype validation)
2. **Week 2:** Implement PCIe BAR0 access, test on hardware
3. **Week 3:** Add DRAM integration via LiteDRAM
4. **Week 4:** Integrate HDMI output via LiteVideo

---

## Related Documentation
- `docs/todo/todo_ip_integration.md` - Full 50-item roadmap
- `docs/todo/todo_board_fpga.md` - FPGA board selection
- `docs/todo/todo_hardware_validation.md` - Hardware bring-up testing
- `third_party/litex/README.md` - LiteX framework documentation

---

**This TODO focuses on UNBLOCKING LiteX integration.** Once these items are complete, we can follow the full roadmap in `todo_ip_integration.md` for comprehensive IP integration.

**Timeline Estimate:** 2-4 weeks to unblock, then follow existing 150-220 day hardware integration plan.

**Status:** Ready for immediate implementation start.</content>
<parameter name="filePath">/home/jon/temp/hydra/docs/todo/todo_litex_status.md
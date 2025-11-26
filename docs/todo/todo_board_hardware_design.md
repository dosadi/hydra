# Custom Board Hardware Design TODO Tracker

**Last Updated:** 2025-11-25
**Owner:** Hardware Design Team
**Related Trackers:** `todo_board_fpga.md`, `todo_hardware_validation.md`, `todo_ip_integration.md`

---

## Overview

Tracks custom PCB design, component selection, connectors/headers, power distribution, signal integrity, manufacturing, and board bring-up. This covers designing a **full custom Hydra accelerator card** from circuit design through manufacturing.

**Priority Distribution:**
- **P0:** 12 items (~25 days) - Critical board architecture and design
- **P1:** 18 items (~35 days) - Component selection, layout, manufacturing prep
- **P2:** 15 items (~25 days) - Advanced features, testing, certification
- **P3:** 8 items (~15 days) - Future enhancements

**Total:** 53 items, ~100 engineer-days

**Note:** This tracker covers **custom board design**. See `todo_board_fpga.md` for FPGA selection and synthesis.

---

## P0 - Critical Board Architecture (Blocks Custom Board Development)

### Board Architecture and Requirements
- **TODO [P0]:** Define board form factor (PCIe card, standalone, FMC module)
  - **Effort:** 3 days
  - **Priority:** P0 - Fundamental architecture decision
  - **Dependencies:** Use case (PCIe desktop card vs. embedded module)
  - **Validation:** Form factor selected, dimensions defined
  - **Deliverable:** Board requirements document
  - **Options:**
    - **PCIe Full-Height Card:** Standard desktop add-in card, ~175mm x 112mm
    - **PCIe Half-Height/Low-Profile:** Compact desktop, ~168mm x 64mm
    - **FMC Module:** VITA 57.1 standard for carrier boards (HPC or LPC)
    - **Standalone Development Board:** Custom dimensions, prototyping

- **TODO [P0]:** Select FPGA package and pinout (BGA, size, I/O count)
  - **Effort:** 3 days
  - **Priority:** P0 - PCB layout prerequisite
  - **Dependencies:** FPGA family selected (Artix-7, Kintex-7, etc.)
  - **Validation:** Package selected, pinout spreadsheet created
  - **Deliverable:** FPGA package selection document
  - **Notes:** Consider BGA size, escape routing, thermal requirements

- **TODO [P0]:** Define power requirements (FPGA core, I/O, PCIe, DRAM)
  - **Effort:** 2 days
  - **Priority:** P0 - Power supply design prerequisite
  - **Dependencies:** FPGA and component selection
  - **Validation:** Power budget spreadsheet complete
  - **Deliverable:** Power requirements document
  - **Typical Values:**
    - FPGA Vccint: 1.0V @ 5-10A (Artix-7)
    - FPGA Vccaux: 1.8V @ 2A
    - FPGA Vcco: 3.3V/2.5V/1.8V @ varies
    - DDR3: 1.5V @ 2-4A
    - PCIe: 3.3V aux, 12V main

- **TODO [P0]:** Create block diagram showing all major components and interfaces
  - **Effort:** 2 days
  - **Priority:** P0 - System architecture clarity
  - **Dependencies:** Requirements defined
  - **Validation:** Block diagram shows FPGA, DRAM, PCIe, power, debug
  - **Deliverable:** System block diagram (PDF/SVG)
  - **Components:**
    - FPGA (Artix-7/Kintex-7/etc.)
    - DDR3/DDR4 SDRAM
    - PCIe edge connector or FMC connector
    - Power supplies (switching regulators)
    - Configuration (QSPI flash, JTAG)
    - Debug headers (UART, GPIO, JTAG)
    - Clocking (oscillators, PCIe refclk)
    - LEDs, buttons, switches

### PCIe Interface Design
- **TODO [P0]:** Design PCIe edge connector footprint (x1/x4/x8/x16)
  - **Effort:** 2 days
  - **Priority:** P0 - Host connectivity
  - **Dependencies:** Form factor selected
  - **Validation:** PCIe edge connector matches standard
  - **Deliverable:** PCIe connector footprint in PCB layout
  - **Standards:** PCI Express Card Electromechanical Specification
  - **Note:** x4 is typical for custom accelerators (balance cost vs. bandwidth)

- **TODO [P0]:** Route PCIe differential pairs (TX/RX lanes) with impedance control
  - **Effort:** 3 days
  - **Priority:** P0 - Signal integrity critical
  - **Dependencies:** PCB stackup defined, impedance calculator
  - **Validation:** Differential impedance 100Ω ±10%, length matching ±5 mil
  - **Deliverable:** PCIe routing complete in layout
  - **Notes:** Length match within lane, across lanes, follow FPGA pin assignments

- **TODO [P0]:** Design PCIe reference clock circuit (100 MHz, low jitter)
  - **Effort:** 2 days
  - **Priority:** P0 - PCIe link training
  - **Dependencies:** Oscillator selection
  - **Validation:** Clock meets PCIe jitter spec (<30ps RMS)
  - **Deliverable:** Refclk schematic and layout
  - **Notes:** Use low-jitter oscillator (SiT9121 or similar), AC coupling, termination

### DRAM Interface Design
- **TODO [P0]:** Select DRAM type and capacity (DDR3/DDR4, size, speed)
  - **Effort:** 2 days
  - **Priority:** P0 - Memory subsystem design
  - **Dependencies:** Bandwidth requirements, FPGA support
  - **Validation:** DRAM chip selected, footprint available
  - **Deliverable:** DRAM selection document
  - **Options:**
    - **DDR3-1333:** 4Gb x16 (512MB), mature, easier routing
    - **DDR3-1866:** 8Gb x16 (1GB), higher bandwidth
    - **DDR4-2133:** Better power, higher capacity, harder routing

- **TODO [P0]:** Design DRAM address/command routing with length matching
  - **Effort:** 3 days
  - **Priority:** P0 - DRAM training and reliability
  - **Dependencies:** DRAM chip selected, PCB stackup
  - **Validation:** Address/command length matched to ±20 mil, impedance 50Ω
  - **Deliverable:** DRAM routing complete
  - **Notes:** Fly-by topology for DDR3, follow FPGA MIG guidelines

- **TODO [P0]:** Design DRAM data (DQ) and strobe (DQS) routing with length matching
  - **Effort:** 3 days
  - **Priority:** P0 - Data integrity
  - **Dependencies:** DRAM address routing complete
  - **Validation:** DQS/DQ length matched to ±5 mil within byte lane
  - **Deliverable:** DRAM data routing complete
  - **Notes:** Tight length matching critical for DDR3-1866+, use serpentine routing

### Power Supply Design
- **TODO [P0]:** Design multi-rail power supply (FPGA core, I/O, DRAM, aux)
  - **Effort:** 4 days
  - **Priority:** P0 - Board functionality
  - **Dependencies:** Power requirements defined
  - **Validation:** All rails meet voltage/current specs, ripple <50mV
  - **Deliverable:** Power supply schematic
  - **Rails:**
    - Vccint: 1.0V @ 10A (buck converter)
    - Vccaux: 1.8V @ 2A (buck or LDO)
    - Vcco: Multiple rails (3.3V, 2.5V, 1.8V)
    - DDR3 VDD: 1.5V @ 4A
    - PCIe 3.3V aux from edge connector
  - **Regulators:** TI TPS543xx, LT3xxx series, or similar

- **TODO [P0]:** Design power sequencing and enable logic (FPGA requirements)
  - **Effort:** 2 days
  - **Priority:** P0 - Prevents FPGA latchup
  - **Dependencies:** Power supply schematic
  - **Validation:** Vccint ramps before Vccaux/Vcco per FPGA datasheet
  - **Deliverable:** Power sequencing schematic and simulation
  - **Notes:** Xilinx requires Vccint first, consult UG470 for Artix-7

---

## P1 - High Priority Component Selection and Layout (Recommended for V1 Board)

### Component Selection
- **TODO [P1]:** Select configuration flash (QSPI, size, speed)
  - **Effort:** 1 day
  - **Priority:** P1 - FPGA boot
  - **Dependencies:** FPGA selected
  - **Validation:** Flash capacity sufficient for bitstream + margin
  - **Deliverable:** Flash chip selected (e.g., Micron N25Q128)
  - **Notes:** Typical Artix-7 bitstream ~4-8MB, use 16MB+ for margin

- **TODO [P1]:** Select oscillators and clock sources (system clock, DRAM, config)
  - **Effort:** 1 day
  - **Priority:** P1 - Clocking
  - **Dependencies:** Clock requirements defined
  - **Validation:** Oscillators meet jitter/accuracy specs
  - **Deliverable:** Oscillator BOM
  - **Typical:**
    - System clock: 100 MHz LVDS oscillator for FPGA
    - PCIe refclk: 100 MHz diff (low jitter <30ps)
    - Config clock: 10 MHz single-ended

- **TODO [P1]:** Select debug connectors (JTAG header, UART header, GPIO breakout)
  - **Effort:** 1 day
  - **Priority:** P1 - Debugging and bring-up
  - **Dependencies:** Debug interfaces defined
  - **Validation:** Standard connectors for easy probe access
  - **Deliverable:** Debug connector BOM and pinout
  - **Connectors:**
    - JTAG: 2x7 or 2x10 header (Xilinx Platform Cable compatible)
    - UART: 1x6 header (FTDI cable compatible)
    - GPIO: 2x20 header for test points

- **TODO [P1]:** Select LEDs, buttons, switches for user interface
  - **Effort:** 0.5 days
  - **Priority:** P1 - Status indication
  - **Dependencies:** I/O requirements
  - **Validation:** Sufficient LEDs for status (power, PCIe link, activity)
  - **Deliverable:** UI component BOM
  - **Typical:**
    - Power LED (green)
    - PCIe link LED (green/amber)
    - Status LEDs (4-8 user-controlled)
    - Reset button, config button

### Layout & Mechanical Readiness
- **TODO [P1]:** Finalize thermal solution (heat sink, fan, airflow) for the selected FPGA and power stage, with CFD or empirical estimates.
  - **Effort:** 2 days
  - **Priority:** P1 - Prevent thermal throttling
  - **Dependencies:** Power dissipation targets, chassis/enclosure
  - **Validation:** Thermal budget spreadsheet + proof-of-concept thermal model (CAD/CFD)
  - **Deliverable:** Thermal spec + mechanical CAD for cooling hardware
- **TODO [P1]:** Define PCB stack-up/signal layer plan for power/PCIe/DRAM, including impedance control and referencing.
  - **Effort:** 1.5 days
  - **Priority:** P1 - SI/PI readiness
  - **Dependencies:** Fabricator capabilities (max layers, spec)
  - **Validation:** Stack-up doc (dielectric, thickness, foil)
  - **Deliverable:** Manufacturer-ready stack-up sheet
- **TODO [P1]:** Author mechanical enclosure/board mounting notes (fasteners, retention, card guide) and supply drawings to fab house.
  - **Effort:** 1 day
  - **Priority:** P1 - Mechanical integration
  - **Dependencies:** Form factor, thermal solution
  - **Validation:** Fabricator/assembler acknowledge mechanical requirements
  - **Deliverable:** Demo mechanical note (PDF + CAD snippet)
- **TODO [P1]:** Document all required PHYs (PCIe PHY, HDMI PHY, DDR PHY, clock/USB PHY) with part numbers and vendor guidance so manufacturing/assembly knows the analog modules needed; tie these notes to `docs/mixed_signal_environment.md` and `todo_board_hardware_design.md`.

### Manufacturing Preparation
- **TODO [P2]:** Build a BOM/per-cost estimate template with multiple component sources to ensure longest lead-time items have alternates.
  - **Effort:** 1 day
  - **Priority:** P2 - Manufacturing readiness
  - **Dependencies:** Component selection, budgets
  - **Validation:** BOM with primary/secondary/tertiary vendors
  - **Deliverable:** BOM spreadsheet + sourcing notes
- **TODO [P2]:** Schedule first-run board spins with incremental validation steps (bare board, partial populate, full populate).
  - **Effort:** 1 day
  - **Priority:** P2 - Risk mitigation
  - **Dependencies:** Fabricator lead time
  - **Validation:** Build plan documented (what gets tested at each spin)
  - **Deliverable:** Spin plan document + pass/fail criteria
- **TODO [P2]:** Capture manufacturing constraints (min trace/space, via aspect, panelization) and feed them into DFM checks or fab notes.
  - **Effort:** 1 day
  - **Priority:** P2 - DFM compliance
  - **Dependencies:** Board stack-up, design rules
  - **Validation:** DFM checklist completed
  - **Deliverable:** DFM memo for assembler

## P2 - Testing, Compliance, and Automation
- **TODO [P2]:** Define a rack-level test fixture (power/PCIe) and a scriptable test sequence that exercises PCIe enumeration, SDRAM training, and power health.
  - **Effort:** 2 days
  - **Priority:** P2 - Bring-up automation
  - **Dependencies:** Known interfaces, firmware
  - **Validation:** Automated script logs + pass/fail summary
  - **Deliverable:** `scripts/board_bringup.sh` plus fixture notes
- **TODO [P2]:** Trace layout review (PDF/annotations) to highlight high-speed nets and associated concerns for peer review sessions.
  - **Effort:** 1 day
  - **Priority:** P2 - Quality assurance
  - **Dependencies:** Completed routing
  - **Validation:** Review minutes with sign-off
  - **Deliverable:** Review deck + annotated layout snapshots
- **TODO [P2]:** Add EMI/ESD considerations (filtering, clampers) to the design and document compliance steps for CE/FCC.
  - **Effort:** 1 day
  - **Priority:** P2 - Regulatory path
  - **Dependencies:** Power/PCIe design
  - **Validation:** EMI plan, recommended parts list
  - **Deliverable:** Compliance section in final board doc
- **TODO [P2]:** Add schematic verification steps to CI (DFM bring-up up to tolerances) by adding automated schematic check scripts to `scripts/`.
  - **Effort:** 1 day
  - **Priority:** P2
  - **Dependencies:** Schematics in version control
  - **Validation:** CI job runs with pass/fail
  - **Deliverable:** `scripts/board_schematics_check.sh`

## P3 - Future Enhancements
- **TODO [P3]:** Investigate modular mezzanine add-ons for Hydra (e.g., attachable DRAM expansions or GPU co-processors) and document requirements.
- **TODO [P3]:** Draft a board maintenance plan (firmware updates, diagnostics, field service) referencing this tracker and `docs/hardware_validation.md`.

- **TODO [P2]:** Integrate analog/Mixed-Signal sims (VAMS/Spice/Xyce/Matlab) for the power/IO rails and signal integrity paths; document the exact tooling, input decks, and regression steps so the board simulation workflow can be reproduced.
- **TODO [P3]:** Add a script (`scripts/board_simulate.sh`) that runs the analog models (VAMS/Spice) and saves the waveforms/logs for each release, producing artifacts referenced in `docs/todo/todo_system_summary_2025_11_25.md`.
- **TODO [P1]:** Author a VAMS-focused checklist covering setup (license, models), verification steps, and drift detection of analog parameters to run before each analog regression.  
- **TODO [P2]:** Build converters that produce netlist inputs for VAMS from existing xschem files, documenting any manual mapping or symbol substitutions required.  
- **TODO [P3]:** Capture the analog verification environment (VM image/container) with VAMS and associated scripts so the analog simulation stack stays reproducible by board engineers.  
- **TODO [P2]:** Publish `docs/mixed_signal_environment.md` (see `scripts/setup_mixed_signal_env.sh`) to document the mixed-signal workspace, license expectations, and artifact layout so new engineers can reproduce the analog flow.  
- **TODO [P3]:** Wire `scripts/board_simulate.sh` into the TODO tracker so board simulations run via the recorded script and artifacts feed back into release notes.

- **TODO [P1]:** Select passives (capacitors, resistors, inductors) with appropriate ratings
  - **Effort:** 2 days
  - **Priority:** P1 - Reliability
  - **Dependencies:** Schematic complete
  - **Validation:** All passives rated for voltage, temperature, tolerance
  - **Deliverable:** Passive component BOM
  - **Notes:** Use X7R/X5R caps for power, 0603/0402 size typical

### PCB Design and Layout
- **TODO [P1]:** Define PCB stackup (layers, impedance, materials)
  - **Effort:** 2 days
  - **Priority:** P1 - Signal integrity foundation
  - **Dependencies:** Board size, complexity estimate
  - **Validation:** Stackup meets impedance targets (50Ω single-ended, 100Ω diff)
  - **Deliverable:** PCB stackup document
  - **Typical 6-layer stackup:**
    - Layer 1: Top signals (components, routing)
    - Layer 2: GND plane
    - Layer 3: Signals (internal routing)
    - Layer 4: Power planes (Vccint, Vccaux, DDR VDD)
    - Layer 5: Signals (internal routing)
    - Layer 6: Bottom signals and GND

- **TODO [P1]:** Place FPGA and critical components (DRAM, power, PCIe)
  - **Effort:** 3 days
  - **Priority:** P1 - Layout foundation
  - **Dependencies:** Footprints complete
  - **Validation:** FPGA centered, DRAM close to FPGA, power supplies near loads
  - **Deliverable:** Component placement complete
  - **Guidelines:**
    - FPGA at center
    - DRAM within 2-3 inches of FPGA
    - Power supplies on edge, heatsink clearance
    - PCIe connector at card edge

- **TODO [P1]:** Route high-speed signals (PCIe, DRAM) with length matching
  - **Effort:** 5 days
  - **Priority:** P1 - Signal integrity
  - **Dependencies:** Component placement complete
  - **Validation:** All diff pairs matched, impedance controlled
  - **Deliverable:** High-speed routing complete
  - **Notes:** Use microstrip/stripline calculators, serpentine tuning

- **TODO [P1]:** Route power distribution network (wide traces, stitching vias)
  - **Effort:** 3 days
  - **Priority:** P1 - Power integrity
  - **Dependencies:** High-speed routing complete
  - **Validation:** Power trace widths meet current capacity, low impedance
  - **Deliverable:** Power routing complete
  - **Guidelines:**
    - Use plane pours where possible
    - Wide traces for high current (Vccint)
    - Stitching vias every 200 mil

- **TODO [P1]:** Add decoupling capacitors (bulk, ceramic) per power supply guidelines
  - **Effort:** 2 days
  - **Priority:** P1 - Power stability
  - **Dependencies:** Component placement
  - **Validation:** Sufficient decoupling per FPGA guidelines (UG470)
  - **Deliverable:** Decoupling cap placement and routing
  - **Typical:**
    - Bulk caps: 100µF tantalum near regulators
    - Ceramic caps: 10µF, 1µF, 0.1µF, 0.01µF near FPGA balls

- **TODO [P1]:** Add test points for critical signals (power rails, clocks, debug)
  - **Effort:** 1 day
  - **Priority:** P1 - Debugging and validation
  - **Dependencies:** Routing near-complete
  - **Validation:** Test points accessible, labeled
  - **Deliverable:** Test point placement
  - **Locations:**
    - All power rails (Vccint, Vccaux, Vcco, DDR VDD)
    - PCIe TX/RX pairs (for scope probing)
    - Clock signals, reset signals

### Design Verification
- **TODO [P1]:** Run DRC (Design Rule Check) to ensure manufacturing compliance
  - **Effort:** 1 day
  - **Priority:** P1 - Manufacturing prerequisite
  - **Dependencies:** Layout complete
  - **Validation:** Zero DRC errors
  - **Deliverable:** Clean DRC report
  - **Checks:** Trace width, spacing, via size, clearances

- **TODO [P1]:** Run signal integrity simulation (PCIe, DRAM eye diagrams)
  - **Effort:** 3 days
  - **Priority:** P1 - High-speed design validation
  - **Dependencies:** Layout complete, SI tools (HyperLynx, ADS)
  - **Validation:** Eye diagrams meet specs, no crosstalk issues
  - **Deliverable:** SI simulation report
  - **Notes:** Focus on PCIe TX/RX, DRAM DQS/DQ

- **TODO [P1]:** Run power integrity simulation (PDN impedance, voltage drop)
  - **Effort:** 2 days
  - **Priority:** P1 - Power stability validation
  - **Dependencies:** Layout complete, PI tools
  - **Validation:** PDN impedance <1Ω at switching frequencies, Vdrop <50mV
  - **Deliverable:** PI simulation report

- **TODO [P1]:** Create thermal model and verify FPGA/regulator cooling
  - **Effort:** 2 days
  - **Priority:** P1 - Thermal management
  - **Dependencies:** Power estimates
  - **Validation:** FPGA Tj <85°C, regulators <125°C under max load
  - **Deliverable:** Thermal analysis report
  - **Solutions:** Heatsinks, airflow, thermal vias

### Manufacturing Preparation
- **TODO [P1]:** Generate manufacturing files (Gerbers, drill files, assembly drawings)
  - **Effort:** 2 days
  - **Priority:** P1 - PCB fabrication
  - **Dependencies:** Layout complete, DRC clean
  - **Validation:** Gerber viewer shows correct stackup, no errors
  - **Deliverable:** Gerber package for fab house
  - **Files:** RS-274X Gerbers, Excellon drill, IPC-356 netlist

- **TODO [P1]:** Create BOM (Bill of Materials) with vendor part numbers
  - **Effort:** 2 days
  - **Priority:** P1 - Assembly
  - **Dependencies:** Schematic and layout complete
  - **Validation:** All components sourced, stock checked
  - **Deliverable:** BOM spreadsheet (Digikey, Mouser, etc.)
  - **Include:** MPN, vendor PN, qty, refdes, description

- **TODO [P1]:** Create assembly drawings and pick-and-place files
  - **Effort:** 1 day
  - **Priority:** P1 - PCBA
  - **Dependencies:** Layout complete
  - **Validation:** Assembly house can manufacture from files
  - **Deliverable:** Assembly package (centroid file, drawings)

---

## P2 - Medium Priority Advanced Features and Testing (Nice-to-Have)

### Advanced Interface Features
- **TODO [P2]:** Add HDMI output connector and routing (if LiteVideo integrated)
  - **Effort:** 3 days
  - **Priority:** P2 - Video output
  - **Dependencies:** LiteVideo IP, HDMI PHY
  - **Validation:** HDMI connector placed, TMDS pairs routed with impedance control
  - **Deliverable:** HDMI interface complete
  - **Notes:** Differential impedance 100Ω, length match ±5 mil

- **TODO [P2]:** Add Ethernet PHY and RJ45 connector (if LiteEth integrated)
  - **Effort:** 4 days
  - **Priority:** P2 - Network connectivity
  - **Dependencies:** Ethernet IP, PHY selection
  - **Validation:** Ethernet interface functional
  - **Deliverable:** Ethernet interface complete
  - **PHY Options:** Marvell 88E1111, Micrel KSZ9031

- **TODO [P2]:** Add USB interface (FTDI chip or native FPGA USB)
  - **Effort:** 3 days
  - **Priority:** P2 - Debug/config interface
  - **Dependencies:** USB requirements
  - **Validation:** USB enumeration successful
  - **Deliverable:** USB interface complete
  - **Options:** FTDI FT2232H (JTAG+UART), native USB PHY

- **TODO [P2]:** Add SD card slot for data storage or config
  - **Effort:** 2 days
  - **Priority:** P2 - Storage option
  - **Dependencies:** I/O availability
  - **Validation:** SD card read/write functional
  - **Deliverable:** SD card interface complete

### Expansion and Flexibility
- **TODO [P2]:** Add GPIO expansion header (PMOD or custom)
  - **Effort:** 1 day
  - **Priority:** P2 - User expansion
  - **Dependencies:** I/O pins available
  - **Validation:** GPIO header accessible, ESD protected
  - **Deliverable:** GPIO header footprint and routing
  - **Options:** Digilent PMOD (2x6 headers), custom 2x20

- **TODO [P2]:** Add I2C bus breakout for sensors/peripherals
  - **Effort:** 1 day
  - **Priority:** P2 - Peripheral expansion
  - **Dependencies:** I2C controller in FPGA
  - **Validation:** I2C bus functional, pull-ups correct
  - **Deliverable:** I2C header and routing

- **TODO [P2]:** Add SPI flash for data storage (separate from config flash)
  - **Effort:** 2 days
  - **Priority:** P2 - Data storage
  - **Dependencies:** SPI controller
  - **Validation:** SPI flash read/write works
  - **Deliverable:** SPI flash footprint and routing

### Manufacturing and Testing
- **TODO [P2]:** Design board-level self-test (BIST) circuitry
  - **Effort:** 3 days
  - **Priority:** P2 - Manufacturing test
  - **Dependencies:** Test strategy defined
  - **Validation:** BIST detects major faults
  - **Deliverable:** BIST implementation in RTL and hardware

- **TODO [P2]:** Add boundary scan (JTAG) test points for ICT
  - **Effort:** 2 days
  - **Priority:** P2 - In-circuit test
  - **Dependencies:** JTAG chain configured
  - **Validation:** Boundary scan detects opens/shorts
  - **Deliverable:** JTAG test infrastructure

- **TODO [P2]:** Create functional test plan (power-on, PCIe link, DRAM, flash)
  - **Effort:** 3 days
  - **Priority:** P2 - Board validation
  - **Dependencies:** Board manufactured
  - **Validation:** Test plan covers all interfaces
  - **Deliverable:** Test plan document and scripts

- **TODO [P2]:** Design test jig or fixture for automated testing
  - **Effort:** 5 days
  - **Priority:** P2 - Production testing
  - **Dependencies:** Test plan complete
  - **Validation:** Test jig can test boards automatically
  - **Deliverable:** Test jig CAD and build files

### Mechanical and Thermal
- **TODO [P2]:** Design heatsink or thermal solution for FPGA and regulators
  - **Effort:** 3 days
  - **Priority:** P2 - Thermal management
  - **Dependencies:** Thermal analysis complete
  - **Validation:** Heatsink fits, thermal resistance adequate
  - **Deliverable:** Heatsink specification or CAD

- **TODO [P2]:** Design PCIe bracket (full-height, half-height, or both)
  - **Effort:** 2 days
  - **Priority:** P2 - Mechanical integration
  - **Dependencies:** Form factor selected
  - **Validation:** Bracket fits standard PCIe slots
  - **Deliverable:** Bracket CAD (STEP or DXF)

- **TODO [P2]:** Add mounting holes and mechanical constraints
  - **Effort:** 1 day
  - **Priority:** P2 - Mechanical stability
  - **Dependencies:** Form factor defined
  - **Validation:** Mounting holes match standard
  - **Deliverable:** Mounting holes in layout

### Compliance and Certification
- **TODO [P2]:** Design for EMC compliance (shielding, filtering, layout practices)
  - **Effort:** 3 days
  - **Priority:** P2 - Regulatory compliance
  - **Dependencies:** Layout in progress
  - **Validation:** EMC pre-compliance testing passes
  - **Deliverable:** EMC design checklist
  - **Practices:** Ground planes, edge filtering, shielded connectors

- **TODO [P2]:** Prepare for FCC/CE certification testing
  - **Effort:** 2 days
  - **Priority:** P2 - Commercial distribution
  - **Dependencies:** EMC design complete
  - **Validation:** Test plan ready for certification lab
  - **Deliverable:** Certification test plan

---

## P3 - Low Priority Future Enhancements (Future Boards)

### Advanced Power Management
- **TODO [P3]:** Add power monitoring ICs (voltage, current, power)
  - **Effort:** 2 days
  - **Priority:** P3 - Telemetry
  - **Dependencies:** I2C bus available
  - **Validation:** Power monitoring readable via I2C
  - **Deliverable:** Power monitor ICs (INA219, etc.)

- **TODO [P3]:** Implement dynamic voltage/frequency scaling (DVFS) hardware support
  - **Effort:** 3 days
  - **Priority:** P3 - Power optimization
  - **Dependencies:** Programmable regulators
  - **Validation:** FPGA can adjust voltage/frequency
  - **Deliverable:** DVFS regulator integration

### Multi-Board and Scalability
- **TODO [P3]:** Add high-speed inter-board connectors (Aurora, LVDS links)
  - **Effort:** 4 days
  - **Priority:** P3 - Multi-board systems
  - **Dependencies:** Multi-board architecture defined
  - **Validation:** Board-to-board link trains
  - **Deliverable:** Inter-board connector and routing

- **TODO [P3]:** Design for stacking or chaining multiple boards
  - **Effort:** 3 days
  - **Priority:** P3 - Scalability
  - **Dependencies:** Multi-board use case
  - **Validation:** Boards can be stacked mechanically and electrically
  - **Deliverable:** Stacking mechanical design

### Advanced Features
- **TODO [P3]:** Add hardware accelerator for specific functions (crypto, compression)
  - **Effort:** 5 days
  - **Priority:** P3 - Specialization
  - **Dependencies:** Use case defined
  - **Validation:** Accelerator integrated and functional
  - **Deliverable:** Accelerator integration

- **TODO [P3]:** Add battery backup for DRAM (preserve state on power loss)
  - **Effort:** 3 days
  - **Priority:** P3 - Data persistence
  - **Dependencies:** Battery management IC
  - **Validation:** DRAM retains data on power loss
  - **Deliverable:** Battery backup circuit

- **TODO [P3]:** Design for conformal coating or potting (harsh environments)
  - **Effort:** 2 days
  - **Priority:** P3 - Ruggedization
  - **Dependencies:** Environmental requirements
  - **Validation:** Board can be coated/potted
  - **Deliverable:** Coating/potting specification

- **TODO [P3]:** Add secure element or TPM for hardware security
  - **Effort:** 4 days
  - **Priority:** P3 - Security
  - **Dependencies:** Security requirements
  - **Validation:** Secure boot, attestation working
  - **Deliverable:** Secure element integration

- **TODO [P3]:** Maintain a board change log documenting every hardware revision, test result, and TODO impact for traceability.
- **TODO [P3]:** Create a short “next board spin” checklist (what to review, what to test) to avoid repeating the same mistakes.

---

## Connector and Header Pinout Reference

### JTAG Header (2x7 or 2x10)
```
Pin 1:  Vref        Pin 2:  NC
Pin 3:  nTRST       Pin 4:  GND
Pin 5:  TDI         Pin 6:  GND
Pin 7:  TMS         Pin 8:  GND
Pin 9:  TCK         Pin 10: GND
Pin 11: RTCK        Pin 12: GND
Pin 13: TDO         Pin 14: GND
```

### UART Header (1x6)
```
Pin 1: GND
Pin 2: CTS (optional)
Pin 3: VCC (3.3V)
Pin 4: TX (from FPGA)
Pin 5: RX (to FPGA)
Pin 6: RTS (optional)
```

### GPIO Expansion (2x20 PMOD-style)
```
Row 1 (Pins 1-20): GPIO0-GPIO15, GND, GND, 3.3V, 3.3V
Row 2 (Pins 21-40): GPIO16-GPIO31, GND, GND, 5V, 5V
```

---

## Manufacturing Vendor Recommendations

### PCB Fabrication
- **Prototype (1-10 boards):** OSH Park, PCBWay, JLCPCB
- **Small batch (10-100):** Advanced Circuits, Sunstone, Bay Area Circuits
- **Production (100+):** TTM Technologies, Sanmina, Flex

### Assembly
- **Prototype assembly:** Screaming Circuits, MacroFab, Bay Area Circuits
- **Production assembly:** Flextronics, Jabil, Sanmina

### Component Sourcing
- **Authorized distributors:** Digikey, Mouser, Arrow, Avnet
- **FPGA:** Direct from Xilinx/AMD or authorized distributors
- **Avoid:** AliExpress, eBay (counterfeit risk for high-value parts)

---

## Design Tool Recommendations

### Schematic and Layout
- **KiCad:** Open-source, free, good for moderate complexity
- **Altium Designer:** Industry standard, expensive, excellent for high-speed
- **EAGLE:** Mid-range, good for hobbyist to professional
- **OrCAD/Allegro:** High-end, complex designs

### Simulation
- **HyperLynx:** Signal/power integrity simulation
- **ADS (Keysight):** Advanced RF and high-speed simulation
- **SPICE (LTSpice):** Power supply and analog simulation

### Thermal Analysis
- **Ansys Icepak:** Comprehensive thermal simulation
- **FloTHERM:** Thermal and CFD analysis
- **Simple calculations:** Junction-to-ambient thermal resistance

---

## Cross-References

**Related Work:**
- See `todo_board_fpga.md` for FPGA selection and synthesis
- See `todo_hardware_validation.md` for board bring-up testing
- See `todo_ip_integration.md` for LitePCIe/LiteDRAM/LiteVideo IP
- See `todo_synthesis.md` for FPGA synthesis optimization

**Blocking Items:**
- P0 board architecture decisions block all PCB design work
- P0 power supply design blocks power-on testing
- P0 PCIe routing blocks host connectivity
- P1 manufacturing files block fabrication

---

## Notes

- **Board design is ~3-6 month effort** for experienced hardware engineer
- **First board revision is rarely perfect** - expect rev B or C before production
- **Signal integrity is critical** for PCIe and high-speed DRAM
- **Work closely with FPGA team** to align pinouts and constraints
- **Manufacturing DFM review** recommended before first fab

**Design Flow:**
1. **Architecture (P0):** Form factor, FPGA, power, block diagram (1-2 weeks)
2. **Schematic (P0/P1):** Component selection, circuit design (2-3 weeks)
3. **Layout (P1):** PCB design, routing, placement (4-6 weeks)
4. **Verification (P1):** DRC, SI/PI simulation, thermal (1-2 weeks)
5. **Manufacturing (P1):** Gerbers, BOM, assembly (1 week)
6. **Fab & Assembly:** PCB fab (2 weeks), assembly (1 week)
7. **Bring-Up (P2):** Power-on, testing, debug (2-4 weeks)

**Next Actions:**
1. Define board form factor (PCIe card vs. FMC vs. standalone)
2. Select FPGA package based on I/O requirements
3. Create power budget spreadsheet
4. Create system block diagram

---

**Document Version:** 1.0
**Created:** 2025-11-25
**Status:** Active tracker for custom board hardware design

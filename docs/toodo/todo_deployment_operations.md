# Hydra Deployment & Operations TODOs (0.0.7+ Cycle)

**Focus:** Packaging, installation, system requirements, deployment guides, operational monitoring.
Ensures the project is easy to install and run in production environments.

**Status:** Mostly P2/P3 work; deployment polish after core functionality stable.

---

## P1: High Priority Deployment (0.0.7 Release)

### System Requirements

- TODO [P1]: Document minimum system requirements
  - **Coverage:**
    - CPU: x86_64 with SSE4.2 (or ARM64)
    - RAM: 4 GB minimum, 8 GB recommended
    - Storage: 1 GB for build artifacts
    - OS: Linux kernel 5.10+, FreeBSD 13.0+ (when driver ready)
    - Dependencies: SDL2, SDL2_ttf, Verilator 5.x
  - **Effort:** Small (2-3 hours)
  - **Dependencies:** None
  - **Validation:** Requirements tested on minimal system
  - **Deliverable:** Section in main README or `docs/system_requirements.md`

- TODO [P1]: Create dependency installation guides
  - **Coverage:**
    - Ubuntu/Debian: apt install commands
    - Fedora/RHEL: dnf install commands
    - Arch: pacman install commands
    - FreeBSD: pkg install commands
    - macOS: brew install commands
  - **Effort:** Small (4 hours)
  - **Dependencies:** None
  - **Validation:** Instructions work on each platform
  - **Deliverable:** `docs/installation.md`

---

## P2: Medium Priority Deployment (Nice-to-Have)

### Packaging

- TODO [P2]: Create Debian package (.deb)
  - **Coverage:**
    - Package: libhydra, libhydra-dev, hydra-tools
    - Dependencies declared
    - Install to /usr/lib, /usr/include, /usr/bin
  - **Effort:** Large (3-5 days)
  - **Dependencies:** Debian packaging knowledge
  - **Validation:** Package installs on Debian/Ubuntu
  - **Deliverable:** `debian/` directory, build scripts

- TODO [P2]: Create RPM package (.rpm)
  - **Coverage:**
    - Package for Fedora/RHEL/openSUSE
    - RPM spec file
  - **Effort:** Large (3-5 days)
  - **Dependencies:** RPM packaging knowledge
  - **Validation:** Package installs on Fedora
  - **Deliverable:** `hydra.spec` file

- TODO [P2]: Create Arch Linux AUR package
  - **Coverage:**
    - PKGBUILD for AUR
    - Build from source
  - **Effort:** Medium (1-2 days)
  - **Dependencies:** None
  - **Validation:** Package installs via yay/paru
  - **Deliverable:** PKGBUILD submitted to AUR

- TODO [P2]: Create Homebrew formula (macOS)
  - **Coverage:**
    - Formula for libhydra and tools
    - Build from source or bottles
  - **Effort:** Medium (1-2 days)
  - **Dependencies:** macOS driver stub functional
  - **Validation:** `brew install hydra-voxel` works
  - **Deliverable:** Homebrew formula PR

- TODO [P2]: Create FreeBSD port
  - **Coverage:**
    - Port in sysutils/hydra or graphics/hydra
    - Makefile for FreeBSD ports
  - **Effort:** Medium (1-2 days)
  - **Dependencies:** FreeBSD driver parity
  - **Validation:** `pkg install hydra` works
  - **Deliverable:** FreeBSD port Makefile

- TODO [P3]: Create Flatpak package
  - **Coverage:**
    - Sandboxed sim package
    - Device access permissions
  - **Effort:** Large (3-5 days)
  - **Dependencies:** Flatpak manifest
  - **Validation:** Works on Flathub
  - **Deliverable:** Flatpak manifest

- TODO [P3]: Create Snap package
  - **Coverage:**
    - Confinement: classic (for device access)
    - Auto-updates
  - **Effort:** Medium (2-3 days)
  - **Dependencies:** Snap manifest
  - **Validation:** Works on Ubuntu Snap Store
  - **Deliverable:** snapcraft.yaml

- TODO [P3]: Create AppImage
  - **Coverage:**
    - Portable binary for Linux
    - Includes all dependencies
  - **Effort:** Medium (1-2 days)
  - **Dependencies:** AppImage tools
  - **Validation:** Runs on any Linux distro
  - **Deliverable:** AppImage build script

### Installation Automation

- TODO [P2]: Create install script for quick setup
  - **Coverage:**
    - Detect distro
    - Install dependencies
    - Build from source
    - Install to system or user directory
  - **Effort:** Medium (1-2 days)
  - **Dependencies:** None
  - **Validation:** Script works on major distros
  - **Deliverable:** `scripts/install.sh`

- TODO [P2]: Add uninstall script
  - **Coverage:**
    - Remove installed files
    - Clean up config
    - Optional: keep user data
  - **Effort:** Small (4 hours)
  - **Dependencies:** Install script
  - **Validation:** Clean uninstall
  - **Deliverable:** `scripts/uninstall.sh`

- TODO [P3]: Create Docker/Podman image
  - **Coverage:**
    - Hydra dev environment in container
    - Pre-built binaries
    - GPU passthrough for hardware
  - **Effort:** Large (3-5 days)
  - **Dependencies:** Dockerfile
  - **Validation:** Container runs sim
  - **Deliverable:** Dockerfile, published image

- TODO [P3]: Add Nix/Guix package
  - **Coverage:**
    - Declarative build
    - Reproducible environment
  - **Effort:** Large (3-5 days)
  - **Dependencies:** Nix/Guix expertise
  - **Validation:** `nix-shell` drops into dev env
  - **Deliverable:** `flake.nix` or `guix.scm`

### System Integration

- TODO [P2]: Create udev rules for device permissions
  - **Coverage:**
    - Auto-set /dev/hydra0 permissions
    - Add to `video` or `render` group
    - Hotplug support
  - **Effort:** Small (4 hours)
  - **Dependencies:** Driver loaded
  - **Validation:** Non-root users can access device
  - **Deliverable:** `udev/99-hydra.rules`

- TODO [P2]: Add systemd service for hardware management
  - **Coverage:**
    - Auto-load driver on boot
    - Graceful shutdown
    - Logging to journal
  - **Effort:** Medium (1-2 days)
  - **Dependencies:** systemd
  - **Validation:** Service starts on boot
  - **Deliverable:** `systemd/hydra.service`

- TODO [P3]: Create OpenRC service (for non-systemd distros)
  - **Coverage:**
    - Alpine, Gentoo, Artix support
    - Init script
  - **Effort:** Small (4 hours)
  - **Dependencies:** None
  - **Validation:** Works on OpenRC systems
  - **Deliverable:** `openrc/hydra`

- TODO [P3]: Add sysvinit script (legacy support)
  - **Coverage:**
    - Traditional init.d script
    - Debian sysvinit support
  - **Effort:** Small (4 hours)
  - **Dependencies:** None
  - **Validation:** Works on sysvinit systems
  - **Deliverable:** `init.d/hydra`

---

## P3: Low Priority Deployment (Future)

### Cloud Deployment

- TODO [P3]: Create cloud VM images
  - **Coverage:**
    - AWS AMI with Hydra pre-installed
    - GCP image
    - Azure image
  - **Effort:** Very Large (10-15 days)
  - **Dependencies:** Cloud accounts, automation
  - **Validation:** Images boot and run Hydra
  - **Deliverable:** Cloud marketplace listings

- TODO [P3]: Add Kubernetes deployment manifests
  - **Coverage:**
    - Deploy Hydra as k8s pod
    - GPU scheduling
    - Persistent storage for scenes
  - **Effort:** Large (5-7 days)
  - **Dependencies:** Kubernetes cluster, GPU support
  - **Validation:** Hydra runs in k8s
  - **Deliverable:** `k8s/` directory with manifests

- TODO [P3]: Create Terraform modules
  - **Coverage:**
    - Provision cloud infrastructure
    - Auto-scale Hydra instances
  - **Effort:** Large (5-7 days)
  - **Dependencies:** Terraform knowledge
  - **Validation:** Infrastructure provisioned correctly
  - **Deliverable:** `terraform/` directory

### Monitoring and Observability

- TODO [P3]: Add Prometheus metrics export
  - **Coverage:**
    - Frame rate, DMA throughput, interrupt count
    - Export via /metrics endpoint
  - **Effort:** Large (3-5 days)
  - **Dependencies:** Prometheus client library
  - **Validation:** Metrics scrapable by Prometheus
  - **Deliverable:** Prometheus exporter

- TODO [P3]: Create Grafana dashboard
  - **Coverage:**
    - Real-time performance graphs
    - Error rate tracking
    - Resource utilization
  - **Effort:** Medium (1-2 days)
  - **Dependencies:** Prometheus metrics
  - **Validation:** Dashboard displays metrics
  - **Deliverable:** Grafana dashboard JSON

- TODO [P3]: Add structured logging (JSON output)
  - **Coverage:**
    - Machine-readable logs
    - Integration with log aggregators (ELK, Splunk)
  - **Effort:** Medium (2-3 days)
  - **Dependencies:** Logging framework
  - **Validation:** Logs parseable by tools
  - **Deliverable:** JSON logging support

- TODO [P3]: Implement health check endpoint
  - **Coverage:**
    - HTTP /health endpoint
    - Returns status (OK, WARNING, ERROR)
    - Useful for load balancers, orchestrators
  - **Effort:** Small (1 day)
  - **Dependencies:** HTTP server (optional)
  - **Validation:** Health check responds correctly
  - **Deliverable:** Health check endpoint

### Configuration Management

- TODO [P3]: Support configuration file (YAML/TOML)
  - **Coverage:**
    - Load settings from file instead of env vars
    - System-wide: /etc/hydra/config.yaml
    - User-local: ~/.config/hydra/config.yaml
  - **Effort:** Medium (2-3 days)
  - **Dependencies:** YAML/TOML parser
  - **Validation:** Config loaded correctly
  - **Deliverable:** Config file support

- TODO [P3]: Add environment variable precedence
  - **Coverage:**
    - Priority: CLI flags > env vars > config file > defaults
    - Document precedence clearly
  - **Effort:** Small (1 day)
  - **Dependencies:** Config system
  - **Validation:** Precedence works as documented
  - **Deliverable:** Config precedence implementation

- TODO [P3]: Create config validation tool
  - **Coverage:**
    - `hydra-config-check` validates config files
    - Reports errors, warnings
  - **Effort:** Small (1 day)
  - **Dependencies:** Config parser
  - **Validation:** Tool catches invalid configs
  - **Deliverable:** `hydra-config-check` utility

### Update and Upgrade

- TODO [P3]: Implement automatic update checks
  - **Coverage:**
    - Check for new releases on startup
    - Notify user of updates
    - Optional: auto-update (with permission)
  - **Effort:** Medium (2-3 days)
  - **Dependencies:** Release API
  - **Validation:** Update notifications work
  - **Deliverable:** Update checker

- TODO [P3]: Create migration guide between versions
  - **Coverage:**
    - Breaking changes documented
    - Migration scripts for config/data
    - Deprecation warnings
  - **Effort:** Medium (ongoing, 1-2 days per major version)
  - **Dependencies:** Version policy
  - **Validation:** Smooth upgrades
  - **Deliverable:** `docs/migration/` directory

### Backup and Recovery

- TODO [P3]: Document data backup procedures
  - **Coverage:**
    - Scene files
    - Config files
    - Driver state (if any)
  - **Effort:** Small (2 hours)
  - **Dependencies:** None
  - **Validation:** Backup/restore tested
  - **Deliverable:** `docs/backup_restore.md`

- TODO [P3]: Add export/import for settings
  - **Coverage:**
    - Export config to portable format
    - Import on new system
  - **Effort:** Small (1 day)
  - **Dependencies:** Config system
  - **Validation:** Export/import works
  - **Deliverable:** Export/import functionality

---

## Operational Documentation

### Troubleshooting Guides

- TODO [P2]: Create common issues troubleshooting guide
  - **Coverage:**
    - "Sim won't build" → check dependencies
    - "Device not found" → check driver loaded
    - "Poor performance" → tune MAX_RAY_STEPS
    - "Frame artifacts" → check golden frame regression
  - **Effort:** Medium (1-2 days)
  - **Dependencies:** Collect common issues
  - **Validation:** Issues resolved by following guide
  - **Deliverable:** `docs/troubleshooting.md`

- TODO [P2]: Document performance tuning for production
  - **Coverage:**
    - Optimal build flags
    - Kernel tuning (e.g., irqbalance)
    - Power management settings
  - **Effort:** Medium (1-2 days)
  - **Dependencies:** Performance profiling
  - **Validation:** Tuning improves performance
  - **Deliverable:** `docs/production_tuning.md`

- TODO [P3]: Create diagnostic data collection script
  - **Coverage:**
    - Collect system info (uname, lsmod, dmesg)
    - Hydra version, build info
    - Config files
    - Generate tarball for bug reports
  - **Effort:** Medium (1-2 days)
  - **Dependencies:** None
  - **Validation:** Diagnostic info helps debug issues
  - **Deliverable:** `scripts/collect_diagnostics.sh`

### Monitoring and Alerts

- TODO [P3]: Define alert thresholds
  - **Coverage:**
    - Frame rate drops below threshold
    - DMA errors exceed rate
    - Interrupt latency spikes
  - **Effort:** Small (4 hours)
  - **Dependencies:** Monitoring infrastructure
  - **Validation:** Alerts fire appropriately
  - **Deliverable:** Alert definitions

- TODO [P3]: Create runbook for common incidents
  - **Coverage:**
    - "Frame rate degradation" → check raymarching complexity
    - "DMA timeout" → check SDRAM health
    - "Driver crash" → check kernel logs
  - **Effort:** Medium (1-2 days)
  - **Dependencies:** Operational experience
  - **Validation:** Incidents resolved faster
  - **Deliverable:** `docs/runbook.md`

---

## Cross-References

- **Build system:** `todo_build_tooling.md` P3 (packaging targets)
- **Documentation:** `todo_documentation.md` (installation guides)
- **Testing:** `todo_testing_ci.md` (package testing)
- **Security:** `todo_security.md` (permissions, device access)
- **Performance:** `todo_performance.md` (production tuning)

---

## Estimated Effort (Deployment & Operations)

| Priority | Items | Effort (days) |
|----------|-------|---------------|
| **P1**   | 2     | 1-2           |
| **P2**   | 13    | 20-35         |
| **P3**   | 26    | 80-140        |
| **Total**| **41**| **101-177**   |

**Note:** P1 items (system requirements, dependency guides) help users install in 0.0.7. P2 items (packaging, system integration) improve deployment experience in 0.0.8. P3 items (cloud, monitoring, config management) are long-term operational polish.

**Recommendation:** Document P1 requirements in Sprint 3 (docs phase). Tackle P2 packaging in 0.0.8 after release. P3 operational features as project matures.

---

**Document Version:** 1.0
**Created:** 2025-11-25
**Target Release:** P1 in 0.0.7, P2 in 0.0.8+, P3 long-term
**Owner:** DevOps team (TBD)

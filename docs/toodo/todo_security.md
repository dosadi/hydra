# Security Hardening TODO Tracker

**Last Updated:** 2025-11-25
**Owner:** Security Team
**Related Trackers:** `todo_mesa_drivers.md`, `todo_testing_ci.md`, `todo_documentation.md`

---

## Overview

Tracks security hardening for driver, userspace tools, and RTL. Focus areas: input validation, bounds checking, privilege separation, fuzzing, security documentation.

**Priority Distribution:**
- **P0:** 0 items - No security blockers for 0.0.7
- **P1:** 8 items (~10 days) - High-value hardening
- **P2:** 16 items (~20 days) - Defense-in-depth
- **P3:** 8 items (~10 days) - Advanced security

**Total:** 32 items, ~40 engineer-days

---

## P1 - High Priority Security Hardening (Recommended for 0.0.7)

### Driver Input Validation
- **TODO [P1]:** Add strict bounds checks for all ioctl parameters (offsets, lengths, ranges)
  - **Effort:** 2 days
  - **Priority:** P1 - Prevent MMIO wrap, OOB access
  - **Dependencies:** None
  - **Validation:** Negative tests confirm -EINVAL on bad params
  - **Deliverable:** Hardened ioctl handlers in hydra_pcie_drv.c
  - **Status:** DONE for DMA ioctl - extend to all ioctls
  - **Notes:** Check src+len, dst+len, register offsets

- **TODO [P1]:** Validate user pointers with access_ok() before copy_from_user/copy_to_user
  - **Effort:** 1 day
  - **Priority:** P1 - Kernel memory protection
  - **Dependencies:** None
  - **Validation:** Invalid pointers return -EFAULT
  - **Deliverable:** access_ok() in all ioctl handlers
  - **Notes:** Prevents kernel memory leaks

- **TODO [P1]:** Add capability checks (CAP_SYS_RAWIO or CAP_SYS_ADMIN) for dangerous ioctls
  - **Effort:** 1 day
  - **Priority:** P1 - Privilege separation
  - **Dependencies:** None
  - **Validation:** Non-root cannot issue DMA or debug writes
  - **Deliverable:** capable() checks in ioctl switch
  - **Notes:** Consider which operations need caps

### Driver Robustness
- **TODO [P1]:** Add rate limiting for debugfs/ioctl operations to prevent DoS
  - **Effort:** 2 days
  - **Priority:** P1 - DoS prevention
  - **Dependencies:** None
  - **Validation:** Rapid ioctl spam doesn't hang kernel
  - **Deliverable:** Rate-limit logic in driver
  - **Notes:** Use token bucket or similar

- **TODO [P1]:** Validate device BAR sizes on probe to prevent driver assuming incorrect layout
  - **Effort:** 1 day
  - **Priority:** P1 - Robustness
  - **Dependencies:** None
  - **Validation:** Driver refuses to load if BAR0 < expected size
  - **Deliverable:** BAR size check in probe()
  - **Notes:** Prevents undefined behavior on wrong hardware

- **TODO [P1]:** Add module parameter validation (vendor ID, device ID ranges)
  - **Effort:** 0.5 days
  - **Priority:** P1 - Config safety
  - **Dependencies:** None
  - **Validation:** Invalid module params rejected at load
  - **Deliverable:** module_param validation callbacks
  - **Notes:** Prevent typos causing probe on wrong device

### Userspace Tool Hardening
- **TODO [P1]:** Add input validation in libhydra (null checks, handle validity, range checks)
  - **Effort:** 2 days
  - **Priority:** P1 - API safety
  - **Dependencies:** None
  - **Validation:** Libhydra handles invalid args gracefully
  - **Deliverable:** Validation in all libhydra APIs
  - **Status:** DONE for basic checks - extend coverage

- **TODO [P1]:** Use secure string functions (strncpy, snprintf) in userspace tools
  - **Effort:** 1 day
  - **Priority:** P1 - Buffer overflow prevention
  - **Dependencies:** None
  - **Validation:** Static analysis shows no unsafe string ops
  - **Deliverable:** Hardened string handling in tools
  - **Notes:** Replace strcpy, sprintf, strcat

---

## P2 - Medium Priority Defense-in-Depth (Nice-to-Have)

### Memory Safety
- **TODO [P2]:** Enable kernel build hardening flags (FORTIFY_SOURCE, STACKPROTECTOR)
  - **Effort:** 1 day
  - **Priority:** P2 - Compiler protections
  - **Dependencies:** Kernel config
  - **Validation:** Driver builds with hardening, tests pass
  - **Deliverable:** Hardening flags in driver Makefile
  - **Notes:** Check for performance impact

- **TODO [P2]:** Add KASAN/UBSAN testing in CI for driver
  - **Effort:** 2 days
  - **Priority:** P2 - Memory bug detection
  - **Dependencies:** CI with KASAN kernel
  - **Validation:** No KASAN warnings during tests
  - **Deliverable:** CI job with sanitizers

- **TODO [P2]:** Add static analysis (sparse, smatch) to driver build
  - **Effort:** 2 days
  - **Priority:** P2 - Bug detection
  - **Dependencies:** Sparse installed
  - **Validation:** Zero warnings from sparse/smatch
  - **Deliverable:** make C=1 in CI

- **TODO [P2]:** Add memory leak detection (kmemleak) testing
  - **Effort:** 2 days
  - **Priority:** P2 - Resource leak detection
  - **Dependencies:** kmemleak enabled kernel
  - **Validation:** No leaks after load/unload cycles
  - **Deliverable:** kmemleak test script

### Privilege and Isolation
- **TODO [P2]:** Add udev rules for device node permissions (non-root access with group)
  - **Effort:** 1 day
  - **Priority:** P2 - User experience + security
  - **Dependencies:** None
  - **Validation:** Users in 'video' group can access /dev/hydra
  - **Deliverable:** udev rules file
  - **Status:** DONE - document in installation guide

- **TODO [P2]:** Add SELinux/AppArmor policy for driver and tools
  - **Effort:** 3 days
  - **Priority:** P2 - Mandatory access control
  - **Dependencies:** SELinux expertise
  - **Validation:** Tools run under confined policy
  - **Deliverable:** SELinux/AppArmor policy files

- **TODO [P2]:** Implement namespace isolation for device access (if applicable)
  - **Effort:** 3 days
  - **Priority:** P2 - Container security
  - **Dependencies:** Namespace support in driver
  - **Validation:** Container can access only its device instance
  - **Deliverable:** Namespace-aware driver

### Fuzzing and Testing
- **TODO [P2]:** Add AFL/libFuzzer harness for ioctl handlers
  - **Effort:** 3 days
  - **Priority:** P2 - Bug discovery
  - **Dependencies:** Fuzzing infrastructure
  - **Validation:** 24hr fuzz finds no crashes
  - **Deliverable:** Fuzz harnesses in tests/

- **TODO [P2]:** Add kcov coverage tracking for driver fuzzing
  - **Effort:** 2 days
  - **Priority:** P2 - Fuzzing effectiveness
  - **Dependencies:** kcov-enabled kernel
  - **Validation:** Coverage maps show ioctl paths exercised
  - **Deliverable:** kcov integration

- **TODO [P2]:** Create negative test suite (invalid ioctls, bad pointers, overflow attempts)
  - **Effort:** 3 days
  - **Priority:** P2 - Attack surface testing
  - **Dependencies:** None
  - **Validation:** All negative tests return expected errors
  - **Deliverable:** scripts/negative_tests.sh
  - **Notes:** Include TOCTOU, race conditions

### Secure Coding Practices
- **TODO [P2]:** Add SAST (Static Application Security Testing) to CI
  - **Effort:** 2 days
  - **Priority:** P2 - Automated security scanning
  - **Dependencies:** SAST tool (CodeQL, Semgrep)
  - **Validation:** CI fails on high-severity findings
  - **Deliverable:** SAST workflow in CI

- **TODO [P2]:** Document security assumptions (trust model, threat boundaries)
  - **Effort:** 2 days
  - **Priority:** P2 - Security design clarity
  - **Dependencies:** None
  - **Validation:** Security team reviews and approves
  - **Deliverable:** docs/security_model.md

- **TODO [P2]:** Add security review checklist for new code (input validation, auth, crypto)
  - **Effort:** 1 day
  - **Priority:** P2 - Process improvement
  - **Dependencies:** None
  - **Validation:** PR template includes security checklist
  - **Deliverable:** SECURITY_CHECKLIST.md

### Cryptography (if applicable)
- **TODO [P2]:** Use kernel crypto API for any cryptographic operations (no custom crypto)
  - **Effort:** 1 day
  - **Priority:** P2 - Crypto correctness
  - **Dependencies:** Crypto requirements defined
  - **Validation:** No custom crypto implementations
  - **Deliverable:** Code review confirms kernel crypto API usage
  - **Notes:** Currently no crypto used

- **TODO [P2]:** Add secure random number generation for any randomness needs
  - **Effort:** 1 day
  - **Priority:** P2 - PRNG quality
  - **Dependencies:** None
  - **Validation:** get_random_bytes() used, not custom PRNG
  - **Deliverable:** Code review confirms

---

## P3 - Low Priority Advanced Security (Future Work)

### Hardened Build
- **TODO [P3]:** Enable kernel Control-Flow Integrity (CFI) when available
  - **Effort:** 2 days
  - **Priority:** P3 - ROP/JOP mitigation
  - **Dependencies:** CFI-enabled kernel
  - **Validation:** Driver builds and runs with CFI
  - **Deliverable:** CFI compatibility

- **TODO [P3]:** Add userspace PIE/ASLR enforcement for tools
  - **Effort:** 1 day
  - **Priority:** P3 - ASLR effectiveness
  - **Dependencies:** None
  - **Validation:** Tools are position-independent
  - **Deliverable:** PIE LDFLAGS in Makefile

- **TODO [P3]:** Enable stack canaries and SafeStack for userspace
  - **Effort:** 1 day
  - **Priority:** P3 - Stack overflow protection
  - **Dependencies:** Compiler support
  - **Validation:** Tools build with stack protection
  - **Deliverable:** Stack protection CFLAGS

### Advanced Isolation
- **TODO [P3]:** Add secure boot signature verification for FPGA bitstreams
  - **Effort:** 5 days
  - **Priority:** P3 - Boot security
  - **Dependencies:** Secure boot infrastructure
  - **Validation:** Unsigned bitstreams rejected
  - **Deliverable:** Signature verification code

- **TODO [P3]:** Implement driver sandboxing with seccomp-bpf or similar
  - **Effort:** 4 days
  - **Priority:** P3 - Syscall filtering
  - **Dependencies:** Seccomp support
  - **Validation:** Driver limited to necessary syscalls
  - **Deliverable:** Seccomp policy

### Security Monitoring
- **TODO [P3]:** Add audit logging for privileged operations
  - **Effort:** 2 days
  - **Priority:** P3 - Security monitoring
  - **Dependencies:** Audit framework
  - **Validation:** Privileged ioctls logged to audit
  - **Deliverable:** Audit events in driver

- **TODO [P3]:** Add intrusion detection hooks (file integrity, behavior monitoring)
  - **Effort:** 3 days
  - **Priority:** P3 - Threat detection
  - **Dependencies:** IDS framework
  - **Validation:** Anomalous behavior triggers alerts
  - **Deliverable:** IDS integration

### Compliance and Certification
- **TODO [P3]:** Prepare for Common Criteria or FIPS certification (if required)
  - **Effort:** 20 days
  - **Priority:** P3 - Certification
  - **Dependencies:** Certification requirements
  - **Validation:** Certification achieved
  - **Deliverable:** Certification documentation

---

## Cross-References

**Related Work:**
- See `todo_mesa_drivers.md` for Windows/macOS driver security
- See `todo_testing_ci.md` for security testing in CI
- See `todo_documentation.md` for security documentation
- See `todo_deployment_operations.md` for secure deployment

**Blocking Items:**
- P1 input validation strongly recommended before 0.0.7
- P1 capability checks recommended for production deployments

---

## Notes

- No P0 security items - security hardening is incremental improvement
- P1 items provide good baseline security for 0.0.7
- P2 items add defense-in-depth
- P3 items are for high-security deployments

**Security Review Process:**
1. P1 items should be reviewed by security team
2. Fuzzing (P2) can run continuously
3. Regular security updates for dependencies

**Next Actions:**
1. Complete ioctl input validation (P1)
2. Add capability checks (P1)
3. Set up fuzzing harness (P2)
4. Document security model (P2)

---

**Document Version:** 1.0
**Created:** 2025-11-25
**Status:** Active tracker for security hardening

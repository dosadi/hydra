# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in Hydra, please report it responsibly:

### For Security Issues

**Do NOT open a public GitHub issue for security vulnerabilities.**

Instead, please report security issues privately:

1. **Preferred:** Use GitHub's private vulnerability reporting feature (if enabled)
   - Go to the Security tab → "Report a vulnerability"

2. **Alternative:** Email the maintainers directly
   - Include "SECURITY" in the subject line
   - Provide detailed information about the vulnerability
   - Include steps to reproduce if possible

### What to Include

When reporting a vulnerability, please include:

- Component affected (RTL, driver, sim, build system)
- Type of vulnerability (buffer overflow, privilege escalation, etc.)
- Steps to reproduce
- Potential impact
- Suggested fix (if you have one)

### Response Timeline

- **Initial Response:** Within 48 hours
- **Status Update:** Within 7 days
- **Fix Timeline:** Varies based on severity and complexity

### Scope

This security policy covers:

- **In Scope:**
  - RTL security issues (e.g., register access control, DMA bounds checking)
  - Driver vulnerabilities (privilege escalation, memory safety)
  - Build system security (malicious build scripts)
  - Simulation harness security issues

- **Out of Scope:**
  - Issues in third-party dependencies (report to upstream)
  - Theoretical attacks requiring physical hardware access
  - Social engineering attacks

### Security Considerations for Hydra

As a hardware accelerator project with kernel drivers:

1. **Driver Security:**
   - IOCTLs should validate all user input
   - BAR0 register access requires proper bounds checking
   - DMA operations must validate addresses and sizes

2. **RTL Security:**
   - Register access control (read/write permissions)
   - DMA range validation in hardware
   - Interrupt masking and privilege separation

3. **Known Alpha Stage Limitations:**
   - Hydra is currently in alpha; drivers are development stubs
   - Production deployments should implement additional hardening
   - Review `docs/component_status.md` for maturity status

## Disclosure Policy

- Security fixes will be released as quickly as possible
- CVE IDs will be requested for significant vulnerabilities
- Credit will be given to reporters (unless anonymity is requested)
- A security advisory will be published after the fix is released

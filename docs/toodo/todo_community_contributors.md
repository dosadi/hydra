# Hydra Community & Contributor TODOs (0.0.7+ Cycle)

**Focus:** Open source engagement, contributor onboarding, community building, governance.
Ensures the project is welcoming and sustainable with external contributions.

**Status:** Mostly P2/P3 work; community building accelerates after initial release.

---

## P2: Medium Priority Community (Post-0.0.7)

### Contributor Onboarding

- TODO [P2]: Create CONTRIBUTING.md guide
  - **Coverage:**
    - How to set up dev environment
    - Code style guidelines (clang-format, naming conventions)
    - Commit message format
    - PR workflow and review process
    - Testing requirements
    - Where to find work (good first issues)
  - **Effort:** Medium (1-2 days)
  - **Dependencies:** Code style formalized
  - **Validation:** New contributors can follow guide successfully
  - **Deliverable:** `CONTRIBUTING.md` in repo root

- TODO [P2]: Add good first issue labels and curation
  - **Coverage:**
    - Label 10-20 issues as "good first issue"
    - Ensure they're well-scoped and documented
    - Provide mentorship offers in issue comments
  - **Effort:** Small (4 hours initial, ongoing)
  - **Dependencies:** GitHub Issues enabled
  - **Validation:** First-time contributors claim issues
  - **Deliverable:** Tagged issues in GitHub

- TODO [P2]: Create developer onboarding checklist
  - **Coverage:**
    - [ ] Clone repo
    - [ ] Install dependencies
    - [ ] Build sim
    - [ ] Run tests
    - [ ] Make small change
    - [ ] Submit PR
  - **Effort:** Small (2 hours)
  - **Dependencies:** Build process documented
  - **Validation:** Checklist complete in <1 hour
  - **Deliverable:** Checklist in CONTRIBUTING.md

- TODO [P2]: Set up GitHub Discussions or Discord
  - **Coverage:**
    - Q&A forum for users/developers
    - Announcements channel
    - Development discussion
    - Showcase area (user projects)
  - **Effort:** Small (4 hours setup, ongoing moderation)
  - **Dependencies:** Community critical mass
  - **Validation:** Active discussions
  - **Deliverable:** Discussion forum or Discord server

### Documentation for Contributors

- TODO [P2]: Write architecture overview for new contributors
  - **Coverage:**
    - High-level system diagram
    - Module responsibilities
    - Data flow
    - Key abstractions
  - **Effort:** Large (3-5 days)
  - **Dependencies:** Architecture stable
  - **Validation:** New contributors understand system
  - **Deliverable:** `docs/architecture_overview.md`

- TODO [P2]: Create code walkthrough documentation
  - **Coverage:**
    - Walkthrough: "How a frame is rendered"
    - Walkthrough: "How DMA works"
    - Walkthrough: "How CSR writes flow"
  - **Effort:** Large (5-7 days for all)
  - **Dependencies:** Code stable
  - **Validation:** Contributors can navigate codebase
  - **Deliverable:** `docs/code_walkthroughs/` directory

- TODO [P2]: Document release process
  - **Coverage:**
    - Version bump procedure
    - Changelog generation
    - Tagging and release notes
    - Artifact building
    - Announcement template
  - **Effort:** Medium (1-2 days)
  - **Dependencies:** Release script exists
  - **Validation:** Release process documented
  - **Deliverable:** `docs/release_process.md`

### Code Review and Quality

- TODO [P2]: Establish code review guidelines
  - **Coverage:**
    - What reviewers should check
    - Response time expectations
    - Review etiquette
    - When to approve vs. request changes
  - **Effort:** Small (4 hours)
  - **Dependencies:** None
  - **Validation:** Consistent review quality
  - **Deliverable:** Section in CONTRIBUTING.md

- TODO [P2]: Set up PR templates
  - **Coverage:**
    - Description template
    - Testing checklist
    - Related issues
    - Breaking changes flag
  - **Effort:** Small (2 hours)
  - **Dependencies:** None
  - **Validation:** PRs use template
  - **Deliverable:** `.github/pull_request_template.md`

- TODO [P2]: Add issue templates
  - **Coverage:**
    - Bug report template
    - Feature request template
    - Documentation improvement template
  - **Effort:** Small (2 hours)
  - **Dependencies:** None
  - **Validation:** Issues use templates
  - **Deliverable:** `.github/ISSUE_TEMPLATE/` directory

### Contributor Recognition

- TODO [P2]: Create AUTHORS or CONTRIBUTORS file
  - **Coverage:**
    - List all contributors
    - Credit for specific features
    - Auto-generate from git log
  - **Effort:** Small (2 hours)
  - **Dependencies:** None
  - **Validation:** Contributors listed
  - **Deliverable:** `AUTHORS.md`

- TODO [P3]: Add contributor hall of fame to docs
  - **Coverage:**
    - Top contributors by commits, reviews, issues
    - Monthly/yearly highlights
  - **Effort:** Medium (1-2 days, scripting)
  - **Dependencies:** Stats tracking
  - **Validation:** Hall of fame updates automatically
  - **Deliverable:** `docs/contributors_hall_of_fame.md`

- TODO [P3]: Create contributor badges/swag
  - **Coverage:**
    - Digital badges for milestones (1st PR, 10 PRs, etc.)
    - Physical stickers for core contributors
  - **Effort:** Medium (1-2 days design, procurement)
  - **Dependencies:** Budget for swag
  - **Validation:** Contributors receive recognition
  - **Deliverable:** Badge system, sticker design

---

## P3: Low Priority Community (Long-Term)

### Community Events

- TODO [P3]: Organize virtual hackathon
  - **Coverage:**
    - 48-hour coding sprint
    - Prizes for best contributions
    - Mentorship from core team
  - **Effort:** Very Large (20-30 days planning + event)
  - **Dependencies:** Active community
  - **Validation:** Successful event, new features merged
  - **Deliverable:** Hackathon event

- TODO [P3]: Present at conferences
  - **Coverage:**
    - Submit talks to open source conferences
    - FOSDEM, XDC, SIGGRAPH, etc.
    - Demo booths
  - **Effort:** Very Large (30-40 days prep + travel)
  - **Dependencies:** Project maturity, budget
  - **Validation:** Conference talks accepted
  - **Deliverable:** Conference presentations

- TODO [P3]: Create monthly development updates
  - **Coverage:**
    - Blog posts on progress
    - Video updates
    - Newsletter
  - **Effort:** Medium (ongoing, 4 hours/month)
  - **Dependencies:** Platform for publishing
  - **Validation:** Community stays informed
  - **Deliverable:** Regular updates

### Educational Content

- TODO [P3]: Create "How it works" blog series
  - **Coverage:**
    - Ray marching algorithm explained
    - Fixed-point arithmetic choices
    - PCIe integration deep-dive
  - **Effort:** Very Large (20-30 days for series)
  - **Dependencies:** Technical writing skills
  - **Validation:** Educational content published
  - **Deliverable:** Blog series

- TODO [P3]: Record development streams
  - **Coverage:**
    - Live coding sessions
    - Architecture discussions
    - Q&A with community
  - **Effort:** Large (ongoing, 2-4 hours/week)
  - **Dependencies:** Streaming setup
  - **Validation:** Streams published
  - **Deliverable:** YouTube/Twitch channel

- TODO [P3]: Create university course materials
  - **Coverage:**
    - Lecture slides on voxel rendering
    - Lab exercises using Hydra
    - Textbook-style documentation
  - **Effort:** Very Large (40-60 days)
  - **Dependencies:** Educational partnerships
  - **Validation:** Used in courses
  - **Deliverable:** Course materials package

### Governance

- TODO [P3]: Establish project governance model
  - **Coverage:**
    - Decision-making process
    - Maintainer roles and responsibilities
    - Contribution criteria
    - Code of conduct
  - **Effort:** Large (3-5 days)
  - **Dependencies:** Core team consensus
  - **Validation:** Governance documented
  - **Deliverable:** `GOVERNANCE.md`

- TODO [P3]: Create code of conduct
  - **Coverage:**
    - Expected behavior
    - Unacceptable behavior
    - Enforcement procedures
    - Contact info for violations
  - **Effort:** Small (4 hours, adapt Contributor Covenant)
  - **Dependencies:** None
  - **Validation:** Code of conduct adopted
  - **Deliverable:** `CODE_OF_CONDUCT.md`

- TODO [P3]: Set up foundation or fiscal sponsor
  - **Coverage:**
    - Legal entity for project
    - Funding management
    - Asset ownership (domain, trademarks)
  - **Effort:** Very Large (30-40 days, legal work)
  - **Dependencies:** Project scale, budget
  - **Validation:** Foundation established
  - **Deliverable:** Foundation or sponsorship agreement

### Community Infrastructure

- TODO [P3]: Set up project website
  - **Coverage:**
    - Landing page with overview
    - Documentation hosting
    - Download links
    - Blog/news
  - **Effort:** Large (5-7 days)
  - **Dependencies:** Domain registration, hosting
  - **Validation:** Website live
  - **Deliverable:** Project website (e.g., hydra-voxel.org)

- TODO [P3]: Create project branding
  - **Coverage:**
    - Logo design
    - Color palette
    - Typography
    - Brand guidelines
  - **Effort:** Large (5-7 days, design)
  - **Dependencies:** Design resources
  - **Validation:** Consistent branding
  - **Deliverable:** Brand assets in `assets/branding/`

- TODO [P3]: Set up continuous integration for community PRs
  - **Coverage:**
    - CI runs on all PRs
    - Automated checks (formatting, tests)
    - Status badges
  - **Effort:** Medium (1-2 days)
  - **Dependencies:** CI infrastructure (DONE in 0.0.7)
  - **Validation:** CI feedback on PRs
  - **Deliverable:** CI configured for external PRs

### Mentorship and Outreach

- TODO [P3]: Create mentorship program
  - **Coverage:**
    - Pair new contributors with mentors
    - Regular check-ins
    - Guided first contributions
  - **Effort:** Large (ongoing, 5-7 days setup)
  - **Dependencies:** Willing mentors
  - **Validation:** Successful mentee PRs
  - **Deliverable:** Mentorship program

- TODO [P3]: Participate in Google Summer of Code
  - **Coverage:**
    - Apply as mentoring organization
    - Define project ideas
    - Mentor students
  - **Effort:** Very Large (40-60 days over summer)
  - **Dependencies:** Project maturity, mentor availability
  - **Validation:** GSoC participation
  - **Deliverable:** GSoC projects completed

- TODO [P3]: Partner with bootcamps/universities
  - **Coverage:**
    - Offer Hydra as project for students
    - Guest lectures
    - Internship opportunities
  - **Effort:** Large (5-7 days outreach + ongoing)
  - **Dependencies:** Educational contacts
  - **Validation:** Partnerships established
  - **Deliverable:** Partnership agreements

---

## Licensing and Legal

### License Management

- TODO [P2]: Ensure LICENSE file is clear and prominent
  - **Current:** Likely already exists (MIT/Apache/GPL?)
  - **Enhancement:** Verify all files have SPDX headers
  - **Effort:** Small (4 hours)
  - **Dependencies:** License choice finalized
  - **Validation:** License clearly documented
  - **Deliverable:** `LICENSE` file, SPDX headers

- TODO [P2]: Document third-party licenses
  - **Coverage:**
    - LiteX IP cores (BSD-2-Clause)
    - SDL2 (Zlib)
    - Verilator (LGPL/Artistic)
    - List all dependencies and their licenses
  - **Effort:** Medium (1-2 days)
  - **Dependencies:** Dependency audit
  - **Validation:** License compliance
  - **Deliverable:** `THIRD_PARTY_LICENSES.md`

- TODO [P3]: Add CLA or DCO for contributions
  - **Coverage:**
    - Contributor License Agreement (CLA) for copyright assignment
    - OR Developer Certificate of Origin (DCO) for sign-offs
  - **Effort:** Medium (1-2 days, legal review)
  - **Dependencies:** Governance decision
  - **Validation:** Contributors sign CLA/DCO
  - **Deliverable:** CLA document or DCO enforcement

### Trademark and Branding

- TODO [P3]: Register "Hydra" trademark
  - **Coverage:**
    - Trademark search
    - Registration in key jurisdictions
    - Enforcement policy
  - **Effort:** Very Large (30-40 days, legal process)
  - **Dependencies:** Budget, legal counsel
  - **Validation:** Trademark registered
  - **Deliverable:** Trademark registration

- TODO [P3]: Create trademark usage guidelines
  - **Coverage:**
    - Permitted uses (educational, compatibility)
    - Prohibited uses (misleading, commercial without permission)
    - Logo usage rules
  - **Effort:** Small (4 hours)
  - **Dependencies:** Trademark registered
  - **Validation:** Guidelines documented
  - **Deliverable:** `docs/trademark_guidelines.md`

---

## Metrics and Analytics

### Community Metrics

- TODO [P3]: Track community health metrics
  - **Coverage:**
    - Number of contributors (monthly active)
    - PR throughput (opened, merged, closed)
    - Issue resolution time
    - Community engagement (discussions, stars, forks)
  - **Effort:** Medium (1-2 days setup, auto-update)
  - **Dependencies:** GitHub API access
  - **Validation:** Metrics dashboard
  - **Deliverable:** Community health dashboard

- TODO [P3]: Survey contributor satisfaction
  - **Coverage:**
    - Quarterly survey: ease of contribution, documentation quality, responsiveness
    - Feedback on pain points
    - Ideas for improvement
  - **Effort:** Small (4 hours per quarter)
  - **Dependencies:** Survey tool
  - **Validation:** Actionable feedback received
  - **Deliverable:** Survey results and action items

---

## Cross-References

- **Documentation:** `todo_documentation.md` (tutorials, API docs)
- **Examples:** `todo_examples_demos.md` (onboarding examples)
- **Build system:** `todo_build_tooling.md` (dev environment setup)
- **Testing:** `todo_testing_ci.md` (CI for external PRs)
- **Security:** `todo_security.md` (vulnerability disclosure in SECURITY.md)

---

## Estimated Effort (Community & Contributors)

| Priority | Items | Effort (days) |
|----------|-------|---------------|
| **P1**   | 0     | 0             |
| **P2**   | 11    | 15-25         |
| **P3**   | 20    | 200-350       |
| **Total**| **31**| **215-375**   |

**Note:** No P1 items; community work is post-release. P2 items (contributor onboarding, docs) help growth after 0.0.7. P3 items (events, governance, branding) are long-term sustainability work.

**Recommendation:** Start P2 contributor onboarding in 0.0.7 Sprint 4 (parallel with release prep). Tackle P2 documentation/process in 0.0.8. P3 governance/events when community reaches critical mass.

---

**Document Version:** 1.0
**Created:** 2025-11-25
**Target Release:** P2 in 0.0.7-0.0.8, P3 long-term
**Owner:** Community team (TBD)

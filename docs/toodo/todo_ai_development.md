# AI Development TODOs

Focuses on AI-assisted workflows, tooling, prompts, and verification for the Hydra stack; these items are “for us” as we build with ML helpers.

- **TODO [P1]:** Document the prompt templates, tool commands, and workflow sequences used by AI agents to update TODO trackers, docs, and RTL so the next agent can pick them up or audit them.  
- **TODO [P2]:** Build a pair of scripts (`scripts/ai_diff_summary.py`, `scripts/ai_todo_sync.py`) that summarize AI-driven diffs and reconcile tracker entries (auto-suggest entries when files change).  
- **TODO [P2]:** Add logging/citation metadata (e.g., `README` section) for AI-authored changes so reviewers know when to give extra scrutiny or request human follow-up.  
- **TODO [P3]:** Draft a lightweight “AI dev roster” guideline that states which areas the AI focuses on (docs, TODOs, instrumentation) and what needs hand-off to humans (RTL, drivers).  

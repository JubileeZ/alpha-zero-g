# Core Operating Beliefs — {{PROJECT_NAME}}

This document records the foundational operating assumptions, architectural philosophies, and design decision logs that guide the {{PROJECT_NAME}} project.

---

## 1. Operating Assumptions & Architectural Beliefs

> Add your project's core beliefs here. Below are inherited harness defaults as a starting point.

### Harness Engineering over Prompt Engineering
Prompt engineering only shapes the immediate message turn. Context and Harness Engineering shape the entire system boundaries. A robust harness (deterministic tool hooks, environment synchronizations, and progressive session-continuity files) solves 90% of model failure points.

### Session Continuity > Model Context Size
Large context windows are highly susceptible to noise and circular reasoning. True development efficiency is achieved by exposing explicit state-tracking files (`progress.md` and `features.json`) that act as external memory, ensuring that new agents starting a fresh session know exactly what was done, what was tested, and where to resume.

---

## 2. Design Decision Register (ADR Log)

Non-trivial, hard-to-reverse architectural decisions are captured as separate, immutable Architectural Decision Records (ADRs) inside `docs/adr/`.

| ADR ID | Decision Title | Status | Date | File Link |
|---|---|---|---|---|
| — | *(no domain ADRs yet — see `docs/adr/OPEN_DECISIONS.md` to begin)* | — | — | — |

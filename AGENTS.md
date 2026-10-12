# CODEX.md - AI Agent & Project Guidelines

This document contains behavioral guidelines, safety constraints, and technical standards for AI agents operating on this project.

---

## 1. Core Operating Principles

### Think Before Coding
- **State assumptions explicitly:** If requirements are ambiguous or uncertain, clarify before writing code.
- **Surface tradeoffs:** If multiple implementation approaches exist, present them rather than picking silently.
- **Push back on complexity:** If a simpler approach exists, propose it. Stop and ask if something is unclear.

### Simplicity First
- **Write minimum required code:** Focus strictly on what was requested—no speculative features or unnecessary configurability.
- **Avoid premature abstraction:** Do not introduce abstractions, helpers, or wrapper classes for single-use code.
- **Keep it minimal:** If a solution can be implemented in 50 lines instead of 200, rewrite it to be simpler.

### Surgical Changes
- **Touch only what is necessary:** Modify only code directly relevant to the user's request. Do not refactor adjacent code, change comments, or reformat untouched files.
- **Respect existing style:** Match surrounding code style, naming conventions, and idioms.
- **Clean up self-created orphans:** Remove imports, variables, or functions rendered unused *by your changes*. Do not remove pre-existing dead code unless explicitly requested.

### Goal-Driven Execution
- **Define verifiable criteria:** Transform vague requests into clear steps with explicit verification checkmarks.
- **Plan multi-step work:** For non-trivial tasks, outline a brief execution plan:
  1. [Step] → verify: [check]
  2. [Step] → verify: [check]
- **Verify continuously:** Confirm changes satisfy acceptance criteria before completing the task.

---

## 2. Technical Stack & GDScript Standards

### Engine & Architecture
- **Engine:** Godot 4.x
- **Language:** GDScript
- **Architecture:** Keep code modular and systems independent whenever possible. Use event-driven designs via signals rather than direct tight coupling.

### GDScript Guidelines
- **Type Safety:** Prefer explicit static typing (`var x: int`, `func foo() -> void`) whenever it improves safety and code clarity.
- **Style:** Follow the official Godot GDScript Style Guide strictly.
- **Clean Code:** Avoid duplicate code (DRY principles).
- **APIs:** Do not use deprecated Godot 3.x or outdated Godot 4.x APIs.

### Performance
- Prioritize low CPU overhead across all systems.
- Avoid heavy calculations, allocations, or node lookups inside `_process(delta)` and `_physics_process(delta)`.
- Avoid constantly instantiating/destroying objects in hot loops.
- Prefer signals over frame-by-frame polling.

---

## 3. Safety & Boundaries

- **File Preservation:** Do not delete existing files without explicit authorization.
- **System Integrity:** Do not replace or rewrite existing systems without explaining the rationale and obtaining approval.
- **Dependencies:** Do not introduce third-party libraries, plugins, or external dependencies without explicit permission.
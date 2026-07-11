# Designing Modules

Design deep modules: cohesive behavior behind low-burden interfaces at intentional seams. A module earns its keep when deleting it would push meaningful complexity into callers.

## Rules

- A module owns one cohesive capability, concept, or policy.
- Interfaces should let callers say what they want, not orchestrate incidental steps.
- Dependency-bearing modules accept dependencies explicitly through intentional seams.
- Domain logic and pure decisions live in the functional core.
- Entrypoints translate protocols; shared business policy belongs in domain or service modules.
- External adapter modules translate framework, persistence, network, SDK, runtime, time, randomness, and telemetry boundaries.
- Avoid pass-through wrappers and future-flexibility interfaces.

## Dependency Defaults

- Outside Effect, prefer constructor injection for dependency-bearing modules.
- Inside Effect, use Services/Tags/Layers instead of dependency bags.
- Depend on the narrow behavior the service consumes, not a mega-repository.
- Add or extend adapters only after auditing existing local modules.

## Seam Test

One production adapter plus one test fake, or two real production adapters, usually makes a seam real. One hypothetical interface is often accidental.

## Review Checks

- Does deleting the module remove complexity instead of relocating it?
- Do callers need to know raw DTOs, framework types, or operation order?
- Are time/randomness/IDs hidden in service logic?
- Are tests forcing internals public?
- Is domain policy living in `utils.ts`, handlers, or adapters?

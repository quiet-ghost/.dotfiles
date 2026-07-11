# Vocabulary

- **Boundary**: Place where data changes trust level or representation: HTTP, RPC, CLI, env, queue, storage, file, runtime hop, third-party SDK.
- **Parser**: Runtime check that returns a refined value or typed failure. Validation that discards the refined value is not enough.
- **Domain Module**: Pure module that owns a domain concept, invariant, parser, predicate, transition, or decision.
- **Service Module**: Module that owns a cohesive use case. It composes domain modules and adapter interfaces, sequences effects, and returns typed outcomes.
- **External Adapter Module**: Module that translates framework, protocol, storage, runtime, SDK, or third-party mechanics.
- **Seam**: Intentional boundary where behavior can vary or be substituted through production structure, not test-only patching.
- **Deep Module**: Small interface hiding substantial policy, ordering, invariants, or mechanics.
- **Accidental Interface**: Interface added for naming symmetry or imagined flexibility, not real variation or boundary translation.
- **Functional Core**: Pure domain logic, parsers, transitions, and decisions.
- **Imperative Shell**: I/O sequencing, persistence, external calls, telemetry, time, randomness, IDs, and dependency failure classification.
- **Typed Failure**: Expected failure modeled in return type or error channel with stable tag and safe context.
- **Defect**: Impossible or unrecoverable bug. Throwing is acceptable here.

Use these terms consistently in reviews, specs, architecture scans, and implementation notes.

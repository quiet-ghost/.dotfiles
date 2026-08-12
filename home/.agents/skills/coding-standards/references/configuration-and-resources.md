# Configuration and Resources

Read environment and runtime configuration once at startup or the earliest composition boundary, parse it into typed values, and pass it inward. Entrypoints own top-level side effects and each resource's acquisition, lifetime, release, cancellation, and interruption behavior.

Keep non-entrypoint imports inert, mutable singleton state at framework boundaries, and time and randomness explicit dependencies.

## Completion check

Configuration is parsed once, failures stay typed until startup, resources have one explicit owner and release path, imports are inert, and time/randomness are explicit.

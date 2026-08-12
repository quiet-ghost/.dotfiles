# Workflows, Transactions, and Idempotency

Use an ordinary call for independent work, a database transaction for atomic changes in one datastore, and a durable workflow for process-loss recovery, redelivery, long delays, compensation, or multiple transaction boundaries. Close transactions before network calls or long-running work.

Assign retry ownership and an explicit duplicate-execution strategy: idempotency key, unique constraint, deduplication record, guarded state transition, transactional outbox, or transactional inbox. State why each retried side effect is safe.

## Completion check

Every changed operation has a lifecycle choice, transaction boundaries exclude network work, retry ownership matches durability, and real duplicate paths have an idempotency strategy at the owning layer.

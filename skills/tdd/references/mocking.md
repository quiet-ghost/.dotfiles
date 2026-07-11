# Mocking

Default: do not patch modules or spy on methods. Replace behavior through real seams.

## Prefer

- Constructor-injected recording fake.
- Effect test layer.
- In-memory or local-substitute adapter.
- Local database/filesystem/server when it is the production seam.
- Cloudflare local runtime bindings when available.

## Avoid

- `vi.mock`, `jest.mock`, `vi.spyOn`, `jest.spyOn` for ordinary domain/service tests.
- Mocking internals instead of testing public behavior.
- Building fake objects that do not satisfy the production contract.

## Exception

Use module mocks only when the repo already depends on that pattern and introducing a real seam would be disproportionate for the current change. State the trade-off.

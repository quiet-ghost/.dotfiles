# OpenCode Service Monitor

## Summary

Add a user-owned Omarchy Quickshell bar plugin that monitors and controls the local shared OpenCode 2 service. The bar indicator shows service state continuously. Its popup opens as a compact operational view and expands into diagnostics.

The monitor uses OpenCode's managed-service registration and V2 HTTP API. It does not treat OpenCode as a systemd unit, inspect its database, expose credentials, or claim to count connected clients.

Effort: **L (1-2 days)**.

## Context / Current State

- OpenCode 2 runs as `~/.opencode/bin/opencode2 serve --service`, not as a systemd service.
- Runtime discovery is stored in `~/.local/state/opencode/service.json` with mode `0600`.
- Private service configuration is stored in `~/.config/opencode/v2/service.json` and is excluded from Stow.
- The configured server currently uses a non-loopback address and HTTP Basic authentication.
- `GET /api/health` reports readiness, version, and PID.
- `GET /api/session/active` reports executing sessions.
- OpenCode does not expose connected client count or identity. Active sessions are the selected workload metric.
- Logs are written to `~/.local/share/opencode/log/opencode.log`; journald is not the useful source.
- Existing UI patterns are available in `stappmus.activity-monitor`: compact/expanded loaders, controllers, watchdog scheduling, keyboard navigation, and destructive-action confirmation.

## Goals

- Show `ready`, `transitioning`, `failed`, `unreachable`, `stale`, `stopped`, or `invalid` service state.
- Show endpoint host/port, version, PID, response latency, active session count, and last successful check.
- Poll health every five seconds without overlapping requests or starting a stopped service.
- Provide start, stop, restart, refresh, expand/collapse, and open-log controls.
- Confirm stop and restart, including the current active-session count in the warning.
- Preserve authentication for non-loopback endpoints without exposing the password to QML, argv, logs, or plugin output.
- Surface actionable failures instead of success-shaped empty data.
- Support pointer and keyboard operation using Omarchy shell components.

## Non-Goals

- Connected client count or client identity.
- Approximate TCP socket counts.
- Remote or manually entered OpenCode servers.
- systemd service creation or supervision.
- Automatic restart after failure.
- Raw SSE event display or event-content logging.
- Reading or querying the OpenCode SQLite database.
- Displaying session IDs, titles, prompts, project paths, or raw logs inside the popup.
- Editing service registration, private service configuration, or credentials.
- Supporting OpenCode V1 endpoints.

## Invariants

- A registration file is discovery data, not proof of liveness.
- `ready` requires HTTP 200 plus health PID/version matching the current registration.
- Polling must never call an API path that implicitly starts the service.
- No secret may cross the helper-to-QML JSON boundary.
- No lifecycle action may signal a PID directly.
- Stop and restart must use `opencode2 service stop|restart` so OpenCode performs instance validation and escalation.
- A failed refresh retains the last successful details while clearly changing the current state.
- At most one snapshot request and one lifecycle action may run concurrently.
- Raw session and event payloads are never retained or displayed; only the validated active-session count is projected.

## Design Constraints

- Quickshell plugins run unsandboxed in the long-running `omarchy-shell` process. Blocking work belongs in a helper process.
- The installed OpenCode build is a `next` preview and V2 schemas may change. Runtime JSON must be validated defensively.
- The service may bind before application startup finishes. HTTP 503 is a transition, while HTTP 500 is a failed startup.
- `opencode2 service status` collapses starting and failed states into `stopped`; it is unsuitable as the monitor's only status source.
- `opencode2 api` may ensure/start a missing service, so routine polling must use direct authenticated HTTP after reading registration.
- Service stop/restart disconnects TUIs and can interrupt in-flight work.
- The endpoint may be non-loopback. Authentication cannot be relaxed for same-host use.

## Alternatives Considered

| Approach | Advantages | Rejected because |
|---|---|---|
| Poll `opencode2 service status` and `opencode2 api` | Minimal helper logic; CLI owns discovery/auth | `api` may start a stopped service; `status` hides transitional and failed owners; repeated CLI startup adds overhead |
| Read registration and call V2 API in a helper | Accurate states; no implicit start; secrets remain outside QML; low overhead | Requires a small parser/auth boundary and tests |
| Persistent SSE subscriber | Fast activity transitions | High-volume volatile stream can include sensitive content; does not expose client count; unnecessary for five-second requirements |
| Inspect TCP sockets | Provides a numeric connection estimate | One TUI can hold many sockets and health probes distort the count; not a client metric |
| Add a systemd user unit | Standard lifecycle and supervision | Conflicts with OpenCode's managed-service ownership and current discovery/ensure protocol |

## Recommendation

Create `ghost.opencode-service` as one bar-widget plugin with:

- `Panel.qml` for compact/expanded presentation and confirmation UI.
- `ServiceController.qml` for polling, process ownership, action convergence, and watchdogs.
- `Model.js` for strict snapshot parsing, state projection, labels, colors, and formatting.
- `scripts/opencode_service.py` as the only boundary that reads registration/auth data, performs HTTP probes, and invokes lifecycle CLI commands.
- `scripts/test_opencode_service.py` for behavior tests through the helper's public command interface.

Use a five-second persistent health poll because continuous bar status is an explicit requirement. Pause normal polling during lifecycle actions, poll convergence every second with a bounded timeout, then return to five seconds.

## Proposed Design

### Bar Indicator

- OpenCode glyph plus a state dot.
- `ready`: normal/positive color.
- `transitioning`: warning color and subtle busy treatment.
- `failed`, `unreachable`, `stale`, `invalid`: urgent color.
- `stopped`: dim color.
- Tooltip: state, host:port, active session count, and last-check age. Do not include credentials or session metadata.

### Compact Popup

- State heading and actionable status message.
- Port, version, active sessions, and latency summary.
- Start when stopped; stop/restart when an owner exists; manual refresh always available.
- Expand button for diagnostics.
- Busy actions disable conflicting controls.

### Expanded Diagnostics

- Endpoint host and port.
- Bind exposure classification: `loopback`, `private`, or `non-loopback`.
- Registration presence and identity-match status.
- Registered PID/version and health PID/version.
- Last attempted check and last successful check.
- Response latency and most recent tagged failure.
- Open logs button.
- Lifecycle controls with inline action result.

Do not show the registration ID, password, active session IDs, full session list, config contents, or raw API payloads.

### Lifecycle Controls

- **Start:** no confirmation. Run `opencode2 service start`, then convergence polling.
- **Stop:** confirm with active-session warning. Run `opencode2 service stop`, then wait for `stopped`.
- **Restart:** confirm with active-session warning. Run `opencode2 service restart`, then wait for a new matching `ready` registration.
- **Refresh:** snapshot only; never starts the service.
- **Open logs:** detached terminal running `tail -f ~/.local/share/opencode/log/opencode.log`. The plugin does not capture or transform log content.

Use `ConfirmDialog` and restore panel focus after cancellation/completion. Action requests snapshot immutable action intent and current active-session count before confirmation.

## Domain Model and Types

Python type sketches define the JSON contract; QML/JS parses the same discriminants.

```python
from typing import Literal, TypedDict

ServiceState = Literal[
    "stopped",
    "transitioning",
    "ready",
    "failed",
    "unreachable",
    "stale",
    "invalid",
]

Exposure = Literal["loopback", "private", "non-loopback", "unknown"]

class EndpointView(TypedDict):
    host: str
    port: int
    exposure: Exposure

class IdentityView(TypedDict):
    registeredPid: int
    healthPid: int | None
    registeredVersion: str
    healthVersion: str | None
    matches: bool

class FailureView(TypedDict):
    tag: Literal[
        "registration_invalid",
        "auth_rejected",
        "health_unreachable",
        "health_mismatch",
        "service_transitioning",
        "service_failed",
        "sessions_unavailable",
        "response_invalid",
        "action_failed",
        "action_timeout",
    ]
    message: str
    recovery: str

class ServiceSnapshot(TypedDict):
    schemaVersion: Literal[1]
    state: ServiceState
    endpoint: EndpointView | None
    identity: IdentityView | None
    activeSessions: int | None
    latencyMs: int | None
    checkedAt: str
    successfulAt: str | None
    failure: FailureView | None

ActionName = Literal["start", "stop", "restart"]

class ActionResult(TypedDict):
    schemaVersion: Literal[1]
    action: ActionName
    accepted: bool
    message: str
    failure: FailureView | None
```

State interpretation:

- Missing registration: `stopped`.
- Invalid/unreadable registration: `invalid`.
- Health 200 with matching PID/version: `ready`.
- Health 503: `transitioning`.
- Health 500: `failed`.
- Timeout/refused/DNS failure: `unreachable`.
- Health succeeds but PID/version differs: `stale`.
- Health 401: `invalid` with `auth_rejected` failure.
- Active-session failure does not demote a matching healthy service; retain `ready`, set `activeSessions: null`, and attach `sessions_unavailable` diagnostics.

## Types, Interfaces, and APIs

### Helper CLI

```text
opencode_service.py snapshot
  stdout: one ServiceSnapshot JSON object
  exit 0: valid snapshot, including stopped/failed states
  exit 2: helper contract/usage defect only

opencode_service.py start|stop|restart
  stdout: one ActionResult JSON object
  exit 0: lifecycle command accepted/completed
  exit 1: expected action failure represented in ActionResult
  exit 2: helper contract/usage defect
```

No password, authorization header, raw stderr, or raw HTTP body is written to stdout/stderr.

### Internal Helper Seams

```python
def read_registration(path: Path) -> RegistrationResult: ...
def probe_health(registration: Registration, timeout_s: float) -> HealthResult: ...
def fetch_active_session_count(registration: Registration, timeout_s: float) -> SessionCountResult: ...
def build_snapshot(registration_path: Path, now: datetime) -> ServiceSnapshot: ...
def run_action(action: ActionName, binary: Path, config_dir: Path) -> ActionResult: ...
```

`RegistrationResult`, `HealthResult`, and `SessionCountResult` are tagged success/error values, not exceptions for expected missing, malformed, HTTP, timeout, or authentication paths. Top-level CLI handling converts unexpected defects into a sanitized `response_invalid` result.

### QML Controller Interface

```qml
// Inputs
property int pollIntervalMs: 5000
property int actionPollIntervalMs: 1000
property int actionTimeoutMs: 30000

// Outputs
property var snapshot
property bool refreshRunning
property bool actionRunning
property string actionName
property string actionStatusText

function refresh()
function runAction(name)
```

The controller owns exactly one snapshot `Process`, one action `Process`, one normal single-shot timer, one convergence timer, and watchdog timers. Requests received during an active snapshot collapse into one queued refresh.

## Seams, Boundaries, Adapters, and Implementations

### Registration Boundary

- Read `~/.local/state/opencode/service.json` only inside Python.
- Require a valid HTTP URL, positive integer PID, optional string version, and optional string password.
- Reject unsupported URL schemes and malformed ports.
- Never return registration ID or password in display JSON.

### HTTP Boundary

- Build Basic auth in memory from the registration password.
- Use short bounded timeouts.
- Read only bounded response bodies.
- Parse and validate `/api/health` and `/api/session/active` independently.
- Use HTTP status plus validated body, not the `healthy: true` field alone, to derive lifecycle state.
- Do not follow endpoint redirects to a different origin.

### Lifecycle Boundary

- Invoke argv directly without a shell.
- Use `~/.opencode/bin/opencode2` with `OPENCODE_CONFIG_DIR=~/.config/opencode/v2`.
- Capture bounded stderr for failure classification, then emit a sanitized recovery message.
- Never use `kill`, `pkill`, PID signaling, registration deletion, or database manipulation.

### Presentation Boundary

- `Model.js` validates `schemaVersion`, discriminants, numbers, and nullable fields before replacing the current model.
- Malformed helper output becomes an explicit `invalid` UI state while preserving prior successful details.
- State colors and labels are derived from the state discriminant in one place.

## Call Stacks and Data Flow

### Five-Second Snapshot

```text
Timer
  -> ServiceController.refresh()
  -> Process [python3, helper, snapshot]
  -> helper reads registration (secret remains in helper)
  -> GET /api/health with Basic auth
  -> validate HTTP status + health body + registration identity
  -> if ready: GET /api/session/active
  -> validate and count only running entries
  -> project sanitized ServiceSnapshot JSON
  -> Model.parseSnapshot(stdout)
  -> controller atomically replaces current UI state
  -> schedule next single-shot poll
```

Failure path:

```text
missing/malformed/timeout/HTTP/schema error
  -> tagged helper result
  -> sanitized snapshot
  -> explicit UI state + recovery text
  -> retain last successful non-secret details
  -> schedule next poll; no automatic lifecycle action
```

### Restart

```text
Restart button/key
  -> snapshot immutable intent + activeSessions
  -> ConfirmDialog
  -> ServiceController.runAction("restart")
  -> pause normal poll; disable lifecycle controls
  -> Process [python3, helper, restart]
  -> argv exec opencode2 service restart
  -> parse ActionResult
  -> on acceptance: snapshot every 1s until matching ready or 30s timeout
  -> inline success/failure status
  -> resume five-second polling
```

Cancel closes confirmation, performs no process action, and restores panel focus.

### Open Logs

```text
Open logs button/key
  -> Quickshell.execDetached([
       "xdg-terminal-exec", "-e", "tail", "-f",
       "/home/ghost/.local/share/opencode/log/opencode.log"
     ])
  -> terminal owns raw log display
```

Resolve the home path before constructing argv; do not rely on shell expansion.

## Files to Add / Change / Delete

Add:

- `home/.config/omarchy/plugins/ghost.opencode-service/manifest.json`
- `home/.config/omarchy/plugins/ghost.opencode-service/Panel.qml`
- `home/.config/omarchy/plugins/ghost.opencode-service/ServiceController.qml`
- `home/.config/omarchy/plugins/ghost.opencode-service/Model.js`
- `home/.config/omarchy/plugins/ghost.opencode-service/scripts/opencode_service.py`
- `home/.config/omarchy/plugins/ghost.opencode-service/scripts/test_opencode_service.py`
- `home/.config/omarchy/plugins/ghost.opencode-service/README.md`

Change:

- `home/.config/omarchy/shell.json`: add `ghost.opencode-service` to the right bar section with `pollIntervalSec: 5` and `openExpanded: false`.

Delete: none.

Suggested manifest settings:

```json
{
  "pollIntervalSec": 5,
  "openExpanded": false
}
```

Use a schema range of 5-60 seconds for polling.

## RGR TDD Test Plan

Implement as vertical behavior slices through `opencode_service.py`'s CLI or `build_snapshot` public seam.

1. **Stopped snapshot:** missing registration emits a valid `stopped` snapshot and performs no HTTP request.
2. **Ready snapshot:** matching registration and health plus active-session payload emits `ready` with the correct count and no secret fields.
3. **Identity safety:** mismatched PID or version emits `stale`, never `ready`.
4. **Lifecycle status:** HTTP 503 maps to `transitioning`; HTTP 500 maps to `failed`.
5. **Boundary failures:** malformed registration, 401, timeout, malformed health JSON, and oversized body each produce the correct sanitized tagged failure.
6. **Session degradation:** healthy service plus invalid/unavailable active-session response remains `ready` with unknown session count and diagnostics.
7. **Action execution:** start/stop/restart invoke the exact argv and config environment and return structured exit/error results without leaking captured secrets.
8. **Projection safety:** property-style fixtures containing arbitrary secret/password/header values never place them in serialized snapshots or failures.
9. **QML smoke check:** load the plugin headlessly or through the shell rescan path and verify compact, expanded, confirmation, stopped, ready, and failure states without QML errors.
10. **Live read-only check:** run `snapshot` against the local service and compare state/PID/version/session count with `opencode2 api` output.
11. **Manual lifecycle check:** with no important active work, confirm start/stop/restart convergence and TUI reconnection behavior.

Run the smallest checks:

```sh
python3 home/.config/omarchy/plugins/ghost.opencode-service/scripts/test_opencode_service.py
python3 home/.config/omarchy/plugins/ghost.opencode-service/scripts/opencode_service.py snapshot | jq
omarchy-shell shell rescanPlugins
```

Lifecycle verification is intentionally manual because it disconnects shared clients and is externally visible.

## Ordered Deliverables

1. **D1: Snapshot helper and tests (M)** - registration parsing, authenticated health, active-session projection, sanitized failures.
2. **D2: Compact read-only widget (M)** - state indicator, five-second controller, port/version/sessions/latency.
3. **D3: Expanded diagnostics (M)** - identity details, exposure, timestamps, recovery messages, open logs.
4. **D4: Lifecycle controls (M)** - confirmations, structured actions, convergence polling, inline results.
5. **D5: Integration and verification (S)** - manifest, `shell.json`, hot-reload smoke test, component tests.

Dependencies: D2 depends on D1; D3 depends on D2; D4 depends on D1 and D2; D5 depends on D1-D4.

## Acceptance Criteria

- The bar reflects a stopped service within five seconds without starting it.
- A healthy matching service shows its port, version, PID, latency, and active-session count.
- Starting, failed, unreachable, stale, auth-rejected, and malformed states are visually distinct and actionable.
- The popup opens compact and expands without losing selection or status.
- Stop and restart require confirmation and mention active sessions when the count is greater than zero.
- Lifecycle controls cannot overlap and recover to polling after success, failure, or timeout.
- The monitor never uses systemd, direct PID signaling, raw database access, or V1 APIs.
- No registration password, authorization header, raw session payload, prompt, title, or project path appears in helper output, QML state, or logs.
- All helper tests pass and the plugin loads without QML warnings/errors.

## Risks and Open Questions

### Risks

- **Preview API drift:** defensive parsing and explicit `invalid` states prevent silent false health; update tests when OpenCode V2 contracts change.
- **Restart disruption:** confirmation shows active-session count and no automatic restart is implemented.
- **Credential leakage:** secrets remain inside the helper; tests assert serialized output cannot contain them.
- **Shell impact:** all I/O is out-of-process, requests are bounded, polls cannot overlap, and watchdogs recover stuck helpers.
- **Non-loopback exposure:** the expanded view labels exposure, but configuration changes remain outside widget scope.
- **Stale registration/PID reuse:** readiness requires registration/health identity match; actions delegate to OpenCode's validated lifecycle commands.

### Resolved Decisions

- Scope is the local shared service only.
- Workload metric is active sessions, not connected clients or TCP estimates.
- Poll interval is five seconds.
- UI opens compact and expands into diagnostics.
- Initial controls include start, stop, restart, refresh, and open logs.
- Stop and restart require confirmation.
- No automatic remediation is performed.

### Open Questions

None blocking implementation.

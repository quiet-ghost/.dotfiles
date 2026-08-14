var states = ["stopped", "transitioning", "ready", "failed", "unreachable", "stale", "invalid"]

function emptySnapshot() {
  return {
    schemaVersion: 0,
    state: "checking",
    endpoint: null,
    identity: null,
    activeSessions: null,
    latencyMs: null,
    checkedAt: "",
    successfulAt: "",
    failure: null
  }
}

function text(value, maximum) {
  return typeof value === "string" ? value.slice(0, maximum || 300) : ""
}

function integer(value, minimum, maximum) {
  var number = Number(value)
  if (!isFinite(number) || Math.floor(number) !== number) return null
  if (number < minimum || number > maximum) return null
  return number
}

function parseFailure(value) {
  if (value === null || value === undefined) return null
  if (typeof value !== "object") return null
  var tag = text(value.tag, 64)
  var message = text(value.message, 400)
  var recovery = text(value.recovery, 400)
  return tag && message ? { tag: tag, message: message, recovery: recovery } : null
}

function parseSnapshot(raw) {
  var value
  try { value = JSON.parse(String(raw || "")) } catch (error) { return emptySnapshot() }
  if (!value || value.schemaVersion !== 1 || states.indexOf(value.state) < 0) return emptySnapshot()

  var endpoint = null
  if (value.endpoint && typeof value.endpoint === "object") {
    var port = integer(value.endpoint.port, 1, 65535)
    var host = text(value.endpoint.host, 255)
    var exposure = text(value.endpoint.exposure, 32)
    if (host && port !== null) endpoint = { host: host, port: port, exposure: exposure || "unknown" }
  }

  var identity = null
  if (value.identity && typeof value.identity === "object") {
    var registeredPid = integer(value.identity.registeredPid, 1, 2147483647)
    var healthPid = value.identity.healthPid === null ? null : integer(value.identity.healthPid, 0, 2147483647)
    if (registeredPid !== null) identity = {
      registeredPid: registeredPid,
      healthPid: healthPid,
      registeredVersion: text(value.identity.registeredVersion, 100),
      healthVersion: value.identity.healthVersion === null ? "" : text(value.identity.healthVersion, 100),
      matches: value.identity.matches === true
    }
  }

  var sessions = value.activeSessions === null ? null : integer(value.activeSessions, 0, 1000000)
  var latency = value.latencyMs === null ? null : integer(value.latencyMs, 0, 600000)
  return {
    schemaVersion: 1,
    state: value.state,
    endpoint: endpoint,
    identity: identity,
    activeSessions: sessions,
    latencyMs: latency,
    checkedAt: text(value.checkedAt, 64),
    successfulAt: value.successfulAt === null ? "" : text(value.successfulAt, 64),
    failure: parseFailure(value.failure)
  }
}

function parseAction(raw) {
  var value
  try { value = JSON.parse(String(raw || "")) } catch (error) { return null }
  if (!value || value.schemaVersion !== 1) return null
  if (["start", "stop", "restart"].indexOf(value.action) < 0) return null
  return {
    action: value.action,
    accepted: value.accepted === true,
    message: text(value.message, 300),
    failure: parseFailure(value.failure)
  }
}

function stateLabel(state) {
  if (state === "ready") return "Ready"
  if (state === "transitioning") return "Transitioning"
  if (state === "failed") return "Startup failed"
  if (state === "unreachable") return "Unreachable"
  if (state === "stale") return "Stale registration"
  if (state === "invalid") return "Invalid"
  if (state === "stopped") return "Stopped"
  return "Checking"
}

function stateGlyph(state) {
  if (state === "ready") return "●"
  if (state === "transitioning" || state === "checking") return "◐"
  if (state === "stopped") return "○"
  return "!"
}

function statusMessage(snapshot) {
  if (snapshot.failure && snapshot.failure.message) return snapshot.failure.message
  if (snapshot.state === "ready") return "The shared OpenCode service is healthy."
  if (snapshot.state === "stopped") return "The shared OpenCode service is not running."
  return "Checking the shared OpenCode service."
}

function endpointText(snapshot) {
  return snapshot.endpoint ? snapshot.endpoint.host + ":" + snapshot.endpoint.port : "—"
}

function sessionsText(snapshot) {
  return snapshot.activeSessions === null ? "—" : String(snapshot.activeSessions)
}

function versionText(snapshot) {
  if (!snapshot.identity) return "—"
  return snapshot.identity.healthVersion || snapshot.identity.registeredVersion || "—"
}

function pidText(snapshot) {
  if (!snapshot.identity) return "—"
  return String(snapshot.identity.healthPid === null ? snapshot.identity.registeredPid : snapshot.identity.healthPid)
}

function latencyText(snapshot) {
  return snapshot.latencyMs === null ? "—" : snapshot.latencyMs + " ms"
}

function timeText(value) {
  if (!value) return "—"
  var date = new Date(value)
  if (isNaN(date.getTime())) return "—"
  return date.toLocaleTimeString(Qt.locale(), "HH:mm:ss")
}

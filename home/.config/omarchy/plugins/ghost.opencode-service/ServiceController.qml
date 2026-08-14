import QtQuick
import Quickshell.Io
import "Model.js" as Model

Item {
  id: root
  width: 0
  height: 0
  visible: false

  property var settings: ({})
  readonly property var snapshot: _snapshot
  readonly property bool refreshRunning: snapshotProc.running
  readonly property bool actionRunning: _actionRunning
  readonly property string actionName: _actionName
  readonly property string actionStatusText: _actionStatusText
  readonly property string lastSuccessfulAt: _lastSuccessfulAt

  property var _snapshot: Model.emptySnapshot()
  property bool _refreshQueued: false
  property bool _actionRunning: false
  property bool _actionAccepted: false
  property string _actionName: ""
  property string _actionStatusText: ""
  property string _lastSuccessfulAt: ""
  property double _actionStartedAt: 0

  readonly property string helperPath: decodeURIComponent(
    String(Qt.resolvedUrl("scripts/opencode_service.py")).replace("file://", ""))
  readonly property int pollIntervalMs: {
    var value = Number(settings && settings.pollIntervalSec !== undefined ? settings.pollIntervalSec : 5)
    if (!isFinite(value)) value = 5
    return Math.max(5, Math.min(60, value)) * 1000
  }

  signal actionFinished(bool success)

  function refresh() {
    pollTimer.stop()
    if (snapshotProc.running) {
      _refreshQueued = true
      return
    }
    snapshotProc.command = ["python3", helperPath, "snapshot"]
    snapshotProc.running = true
    snapshotWatchdog.restart()
  }

  function consumeSnapshot(raw) {
    var next = Model.parseSnapshot(raw)
    if (next.schemaVersion !== 1) {
      _actionStatusText = "Monitor returned an invalid snapshot."
      return
    }
    _snapshot = next
    if (next.successfulAt) _lastSuccessfulAt = next.successfulAt
    if (_actionRunning && _actionAccepted) checkActionConvergence()
  }

  function runAction(name) {
    if (_actionRunning || ["start", "stop", "restart"].indexOf(name) < 0) return
    pollTimer.stop()
    convergenceTimer.stop()
    _actionRunning = true
    _actionAccepted = false
    _actionName = name
    _actionStatusText = name.charAt(0).toUpperCase() + name.slice(1) + " requested…"
    _actionStartedAt = Date.now()
    actionProc.command = ["python3", helperPath, name]
    actionProc.running = true
    actionWatchdog.restart()
  }

  function consumeAction(raw) {
    var result = Model.parseAction(raw)
    if (!result) {
      finishAction(false, "OpenCode returned an invalid action result.")
      return
    }
    if (!result.accepted) {
      finishAction(false, result.failure ? result.failure.message : result.message)
      return
    }
    _actionAccepted = true
    _actionStatusText = "Waiting for service " + (_actionName === "stop" ? "shutdown…" : "readiness…")
    convergenceTimer.restart()
    refresh()
  }

  function checkActionConvergence() {
    var converged = _actionName === "stop" ? _snapshot.state === "stopped" : _snapshot.state === "ready"
    if (converged) {
      finishAction(true, _actionName.charAt(0).toUpperCase() + _actionName.slice(1) + " completed.")
      return
    }
    if (Date.now() - _actionStartedAt >= 30000) {
      finishAction(false, "Service did not reach the expected state in 30 seconds.")
      return
    }
    convergenceTimer.restart()
  }

  function finishAction(success, message) {
    actionWatchdog.stop()
    convergenceTimer.stop()
    _actionRunning = false
    _actionAccepted = false
    _actionStatusText = String(message || "")
    actionFinished(success)
    pollTimer.restart()
  }

  Component.onCompleted: refresh()

  Process {
    id: snapshotProc
    command: []
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.consumeSnapshot(text)
    }
    onExited: {
      snapshotWatchdog.stop()
      if (root._refreshQueued) {
        root._refreshQueued = false
        Qt.callLater(root.refresh)
      } else if (!root._actionRunning) pollTimer.restart()
    }
  }

  Process {
    id: actionProc
    command: []
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.consumeAction(text)
    }
    onExited: actionWatchdog.stop()
  }

  Timer {
    id: pollTimer
    interval: root.pollIntervalMs
    repeat: false
    onTriggered: root.refresh()
  }

  Timer {
    id: convergenceTimer
    interval: 1000
    repeat: false
    onTriggered: root.refresh()
  }

  Timer {
    id: snapshotWatchdog
    interval: 8000
    repeat: false
    onTriggered: {
      if (snapshotProc.running) snapshotProc.running = false
      root._actionStatusText = "Service check timed out."
      if (root._actionRunning && root._actionAccepted) root.checkActionConvergence()
      else pollTimer.restart()
    }
  }

  Timer {
    id: actionWatchdog
    interval: 35000
    repeat: false
    onTriggered: {
      if (actionProc.running) actionProc.running = false
      root.finishAction(false, "OpenCode service action timed out.")
    }
  }
}

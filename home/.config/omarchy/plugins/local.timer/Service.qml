import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property var shell: null
  property bool active: false
  property int remaining: 0
  property string label: ""
  property string kind: "timer"
  property int cycle: 0
  property int completedFocusCycles: 0
  property string nextPomodoroKind: "focus"
  property string error: ""
  property bool pendingPomodoroReset: false

  readonly property string displayTime: formatTime(remaining)
  readonly property string nextPomodoroLabel: nextPomodoroKind === "focus"
    ? "Start focus " + String(completedFocusCycles + 1)
    : (nextPomodoroKind === "long-break" ? "Start long break" : "Start short break")

  function formatTime(total) {
    var value = Math.max(0, Number(total) || 0)
    var hours = Math.floor(value / 3600)
    var minutes = Math.floor((value % 3600) / 60)
    var seconds = Math.floor(value % 60)
    var mm = String(minutes).padStart(2, "0")
    var ss = String(seconds).padStart(2, "0")
    return hours > 0 ? String(hours) + ":" + mm + ":" + ss : mm + ":" + ss
  }

  function run(command) {
    if (actionProcess.running) return false
    error = ""
    actionProcess.command = command
    actionProcess.running = true
    return true
  }

  function startMinutes(minutes, timerLabel) {
    var value = Math.max(1, Math.min(1440, Number(minutes) || 0))
    return run(["omarchy-timer", "start", String(value) + "m", timerLabel || String(value) + " minute timer", "timer", "0"])
  }

  function startPomodoro() {
    if (active) return false
    if (nextPomodoroKind === "focus")
      return run(["omarchy-timer", "start", "25m", "Pomodoro focus", "focus", String(completedFocusCycles + 1)])
    if (nextPomodoroKind === "long-break")
      return run(["omarchy-timer", "start", "15m", "Pomodoro long break", "long-break", String(completedFocusCycles)])
    return run(["omarchy-timer", "start", "5m", "Pomodoro short break", "short-break", String(completedFocusCycles)])
  }

  function cancel() { return run(["omarchy-timer", "cancel"]) }

  function resetPomodoro() {
    if (actionProcess.running) return false
    if (!active) {
      pendingPomodoroReset = true
      return run(["omarchy-timer", "acknowledge"])
    }
    if (["focus", "short-break", "long-break"].indexOf(kind) === -1) {
      completedFocusCycles = 0
      nextPomodoroKind = "focus"
      return true
    }
    pendingPomodoroReset = true
    return cancel()
  }

  function refresh() {
    if (stateProcess.running) return
    stateProcess.command = ["omarchy-timer", "state"]
    stateProcess.running = true
  }

  function applyState(raw) {
    try {
      var state = JSON.parse(String(raw || "{}"))
      active = state.active === true
      remaining = Number(state.remaining) || 0
      label = String(state.label || "")
      kind = String(state.kind || "timer")
      cycle = Number(state.cycle) || 0

      if (active && kind === "focus") {
        completedFocusCycles = Math.max(0, cycle - 1)
        nextPomodoroKind = "focus"
      } else if (active && (kind === "short-break" || kind === "long-break")) {
        completedFocusCycles = Math.max(completedFocusCycles, cycle)
        nextPomodoroKind = kind
      }

      var finished = state.finished || {}
      var finishedKind = String(finished.kind || "")
      if (finishedKind !== "") {
        var finishedCycle = Number(finished.cycle) || 0
        if (finishedKind === "focus") {
          completedFocusCycles = Math.max(completedFocusCycles, finishedCycle)
          nextPomodoroKind = completedFocusCycles > 0 && completedFocusCycles % 4 === 0 ? "long-break" : "short-break"
        } else if (finishedKind === "short-break" || finishedKind === "long-break") {
          completedFocusCycles = Math.max(completedFocusCycles, finishedCycle)
          nextPomodoroKind = "focus"
        }
      }
      error = ""
    } catch (e) {
      error = "Timer state could not be read"
    }
  }

  Timer {
    interval: 1000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Process {
    id: stateProcess
    command: []
    stdout: StdioCollector { id: stateOutput; waitForEnd: true }
    onExited: function(exitCode) {
      if (exitCode === 0) root.applyState(stateOutput.text)
      else root.error = "omarchy-timer state failed"
    }
  }

  Process {
    id: actionProcess
    command: []
    stderr: StdioCollector { id: actionError; waitForEnd: true }
    onExited: function(exitCode) {
      if (exitCode !== 0) root.error = String(actionError.text || "Timer action failed").trim()
      if (root.pendingPomodoroReset) {
        if (exitCode === 0) {
          root.completedFocusCycles = 0
          root.nextPomodoroKind = "focus"
        }
        root.pendingPomodoroReset = false
      }
      root.refresh()
    }
  }

  IpcHandler {
    target: "local.timer"
    function start(minutes: int): string { return root.startMinutes(minutes, "") ? "ok" : "busy" }
    function pomodoro(): string { return root.startPomodoro() ? "ok" : "busy" }
    function cancel(): string { return root.cancel() ? "ok" : "busy" }
    function status(): string { return root.active ? root.displayTime : "idle" }
  }
}

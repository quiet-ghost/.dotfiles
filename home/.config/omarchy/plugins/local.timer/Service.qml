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
  property var presets: [5, 10, 15, 25, 30, 45, 50, 60]
  property var pomodoroPresets: [
    { name: "Classic", focus: 25, shortBreak: 5, longBreak: 15, longEvery: 4 }
  ]
  property var currentPomodoro: pomodoroPresets[0]

  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string presetsPath: home + "/.config/omarchy/timer-presets.json"
  readonly property string pomodoroPath: home + "/.config/omarchy/timer-pomodoro.json"

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

  function startFocus(minutes) {
    if (active) return false
    var value = Math.max(1, Math.min(1440, Number(minutes) || 25))
    return run(["omarchy-timer", "start", String(value) + "m", "Focus " + String(value) + "m", "focus", String(completedFocusCycles + 1)])
  }

  function pomodoroConfig() {
    return currentPomodoro || { name: "Classic", focus: 25, shortBreak: 5, longBreak: 15, longEvery: 4 }
  }

  function startPomodoro(preset) {
    if (preset) currentPomodoro = preset
    if (active) return false
    var pomo = pomodoroConfig()
    if (nextPomodoroKind === "focus") return startFocus(pomo.focus)
    if (nextPomodoroKind === "long-break")
      return run(["omarchy-timer", "start", String(pomo.longBreak) + "m", pomo.name + " long break", "long-break", String(completedFocusCycles)])
    return run(["omarchy-timer", "start", String(pomo.shortBreak) + "m", pomo.name + " short break", "short-break", String(completedFocusCycles)])
  }

  function cancel() { return run(["omarchy-timer", "cancel"]) }

  function normalizePreset(minutes) {
    return Math.max(1, Math.min(1440, Math.round(Number(minutes) || 0)))
  }

  function applyPresets(raw) {
    try {
      var parsed = JSON.parse(String(raw || "[]"))
      if (!Array.isArray(parsed)) return
      var next = []
      for (var i = 0; i < parsed.length; i++) {
        var value = normalizePreset(parsed[i])
        if (next.indexOf(value) === -1) next.push(value)
      }
      next.sort(function(left, right) { return left - right })
      if (next.length > 0) presets = next
    } catch (e) {
    }
  }

  function savePresets() {
    if (writePresets.running) return
    writePresets.command = [
      "python3", "-c",
      "import json, pathlib, sys\npathlib.Path(sys.argv[1]).write_text(json.dumps(json.loads(sys.argv[2]), indent=2) + chr(10))\n",
      presetsPath,
      JSON.stringify(presets)
    ]
    writePresets.running = true
  }

  function addPreset(minutes) {
    var value = normalizePreset(minutes)
    if (value < 1) return false
    var next = presets.slice()
    if (next.indexOf(value) !== -1) return false
    next.push(value)
    next.sort(function(left, right) { return left - right })
    presets = next
    savePresets()
    return true
  }

  function normalizePomodoro(raw) {
    var item = raw && typeof raw === "object" ? raw : {}
    var name = String(item.name || "").trim()
    var focus = normalizePreset(item.focus)
    var shortBreak = normalizePreset(item.shortBreak)
    var longBreak = normalizePreset(item.longBreak)
    var longEvery = Math.max(1, Math.min(12, Math.round(Number(item.longEvery) || 4)))
    if (name === "" || focus < 1 || shortBreak < 1 || longBreak < 1) return null
    return { name: name, focus: focus, shortBreak: shortBreak, longBreak: longBreak, longEvery: longEvery }
  }

  function applyPomodoros(raw) {
    try {
      var parsed = JSON.parse(String(raw || "[]"))
      if (!Array.isArray(parsed)) return
      var next = []
      for (var i = 0; i < parsed.length; i++) {
        var item = normalizePomodoro(parsed[i])
        if (item) next.push(item)
      }
      if (next.length === 0) return
      pomodoroPresets = next
      if (!currentPomodoro) currentPomodoro = next[0]
    } catch (e) {
    }
  }

  function savePomodoros() {
    if (writePomodoros.running) return
    writePomodoros.command = [
      "python3", "-c",
      "import json, pathlib, sys\npathlib.Path(sys.argv[1]).write_text(json.dumps(json.loads(sys.argv[2]), indent=2) + chr(10))\n",
      pomodoroPath,
      JSON.stringify(pomodoroPresets)
    ]
    writePomodoros.running = true
  }

  function addPomodoro(name, focus, shortBreak, longBreak, longEvery) {
    var item = normalizePomodoro({
      name: name,
      focus: focus,
      shortBreak: shortBreak,
      longBreak: longBreak,
      longEvery: longEvery
    })
    if (!item) return false
    var next = pomodoroPresets.slice()
    for (var i = 0; i < next.length; i++) {
      if (next[i].name === item.name) return false
    }
    next.push(item)
    pomodoroPresets = next
    if (!currentPomodoro) currentPomodoro = item
    savePomodoros()
    return true
  }

  function removePomodoro(name) {
    var next = []
    for (var i = 0; i < pomodoroPresets.length; i++) {
      if (pomodoroPresets[i].name !== name) next.push(pomodoroPresets[i])
    }
    if (next.length === 0) return false
    pomodoroPresets = next
    if (currentPomodoro && currentPomodoro.name === name) currentPomodoro = next[0]
    savePomodoros()
    return true
  }

  function removePreset(minutes) {
    var value = normalizePreset(minutes)
    var next = []
    for (var i = 0; i < presets.length; i++) {
      if (presets[i] !== value) next.push(presets[i])
    }
    if (next.length === 0) return false
    presets = next
    savePresets()
    return true
  }

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
          var every = Math.max(1, Number(pomodoroConfig().longEvery) || 4)
          nextPomodoroKind = completedFocusCycles > 0 && completedFocusCycles % every === 0 ? "long-break" : "short-break"
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

  FileView {
    id: presetsFile
    path: root.presetsPath
    watchChanges: true
    printErrors: false
    onLoaded: root.applyPresets(text())
  }

  FileView {
    id: pomodoroFile
    path: root.pomodoroPath
    watchChanges: true
    printErrors: false
    onLoaded: root.applyPomodoros(text())
  }

  Process {
    id: writePresets
    running: false
  }

  Process {
    id: writePomodoros
    running: false
  }

  IpcHandler {
    target: "local.timer"
    function start(minutes: int): string { return root.startMinutes(minutes, "") ? "ok" : "busy" }
    function pomodoro(): string { return root.startPomodoro() ? "ok" : "busy" }
    function cancel(): string { return root.cancel() ? "ok" : "busy" }
    function status(): string { return root.active ? root.displayTime : "idle" }
  }
}

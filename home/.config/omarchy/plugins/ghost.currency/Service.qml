import QtQuick
import Quickshell
import Quickshell.Io
import "Model.js" as Model

Item {
  id: root

  property var shell: null
  property string fromCode: "USD"
  property string toCode: "JPY"
  property string amountText: "1"
  property var rates: ({ USD: 1 })
  property string rateDate: ""
  property string error: ""
  property bool refreshing: false

  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string statePath: home + "/.local/state/omarchy/currency.json"
  readonly property var currencyOptions: Model.currencyOptions()
  readonly property real amount: {
    var parsed = Model.parseAmount(root.amountText)
    return parsed === null ? 0 : parsed
  }
  readonly property var converted: Model.convert(root.amount, root.fromCode, root.toCode, root.rates)
  readonly property string convertedText: root.converted === null ? "—" : Model.formatAmount(root.converted, root.toCode, false)
  readonly property string displayText: Model.barLabel(root.amount, root.fromCode, root.toCode, root.rates)
  readonly property string rateText: Model.rateLabel(root.fromCode, root.toCode, root.rates)
  readonly property bool ready: root.converted !== null

  function setAmount(text) {
    var next = String(text || "")
    if (root.amountText === next) return
    root.amountText = next
    root.saveSoon()
  }

  function setFrom(code) {
    var next = Model.normalizeCode(code, root.fromCode)
    if (next === root.fromCode) return
    if (next === root.toCode) {
      root.swap()
      return
    }
    root.fromCode = next
    root.saveSoon()
  }

  function setTo(code) {
    var next = Model.normalizeCode(code, root.toCode)
    if (next === root.toCode) return
    if (next === root.fromCode) {
      root.swap()
      return
    }
    root.toCode = next
    root.saveSoon()
  }

  function swap() {
    var next = Model.swapState(root.fromCode, root.toCode, root.amount, root.rates)
    root.fromCode = next.from
    root.toCode = next.to
    root.amountText = next.amountText
    root.saveSoon()
  }

  function applyState(raw) {
    var next = Model.applyState(raw)
    root.fromCode = next.from
    root.toCode = next.to
    root.amountText = next.amountText
  }

  function saveSoon() {
    saveTimer.restart()
  }

  function saveState() {
    if (writeState.running) return
    writeState.command = [
      "python3", "-c",
      "import json, pathlib, sys\npath = pathlib.Path(sys.argv[1])\npath.parent.mkdir(parents=True, exist_ok=True)\npath.write_text(json.dumps(json.loads(sys.argv[2]), indent=2) + chr(10))\n",
      root.statePath,
      JSON.stringify({ from: root.fromCode, to: root.toCode, amountText: root.amountText })
    ]
    writeState.running = true
  }

  function applyRates(raw) {
    var parsed = Model.parseRates(raw)
    if (!parsed.ok) {
      root.error = "Exchange rates could not be read"
      return
    }
    root.rates = parsed.rates
    root.rateDate = parsed.date
    root.error = ""
  }

  function refresh() {
    if (rateProcess.running) return false
    root.refreshing = true
    root.error = ""
    rateProcess.command = ["curl", "-fsS", "--max-time", "8", Model.ratesUrl()]
    rateProcess.running = true
    return true
  }

  FileView {
    path: root.statePath
    watchChanges: true
    printErrors: false
    onLoaded: root.applyState(text())
  }

  Timer {
    id: saveTimer
    interval: 400
    repeat: false
    onTriggered: root.saveState()
  }

  Timer {
    interval: 900000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Process {
    id: rateProcess
    command: []
    stdout: StdioCollector { id: rateOutput; waitForEnd: true }
    stderr: StdioCollector { id: rateError; waitForEnd: true }
    onExited: function(exitCode) {
      root.refreshing = false
      if (exitCode === 0) root.applyRates(rateOutput.text)
      else root.error = String(rateError.text || "Could not fetch exchange rates").trim()
    }
  }

  Process {
    id: writeState
    running: false
  }

  IpcHandler {
    target: "ghost.currency"
    function refresh(): string { return root.refresh() ? "ok" : "busy" }
    function swap(): string { root.swap(); return "ok" }
    function status(): string { return root.displayText }
  }
}

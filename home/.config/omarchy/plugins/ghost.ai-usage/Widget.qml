import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// Laid out the way omarchy.agents is: a hero with a rotating summary, then one
// page of providers split by rules, limits first. What Agents doesn't have is
// kept on top of that: the Subs / APIs views, per-provider token breakdowns
// (collapsed under each header), and a view assignment for every provider.
Panel {
  id: root
  moduleName: "ghost.ai-usage"
  ipcTarget: "ghost.ai-usage"
  manageIpc: false

  // Items inside the panel's lazily built content, null until it first opens.
  readonly property Item panelFlick: panel.loadedContent ? panel.loadedContent.panelFlick : null
  readonly property Item hero: panel.loadedContent ? panel.loadedContent.hero : null
  readonly property Item column: panel.loadedContent ? panel.loadedContent.column : null

  readonly property color foreground: bar ? bar.foreground : Commons.Color.foreground
  readonly property color urgent: bar ? bar.urgent : Commons.Color.urgent
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property color track: Style.selectedFillFor(foreground, Commons.Color.accent)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  readonly property int refreshIntervalSec: Math.max(30, Number(setting("refreshIntervalSec", 300)))
  readonly property string scannerPath: pathFromUrl(Qt.resolvedUrl("scripts/ai_usage.py"))
  readonly property string omarchyPath: Quickshell.env("OMARCHY_PATH") || "/usr/share/omarchy"

  property string activeView: String(setting("defaultView", "subs")) === "apis" ? "apis" : "subs"
  property bool settingsMode: false
  property bool refreshing: false
  property bool rescanPending: false
  property string pendingOmarchyUpdate: ""
  property var snapshot: ({ schemaVersion: 1, catalog: [], providers: [], views: { subs: [], apis: [] } })
  property var assignments: ({})
  // Provider id -> showing its token breakdown. Lives here because refreshes
  // rebuild the sections.
  property var expanded: ({})

  // Countdowns read this instead of Date.now() so they keep telling the truth
  // while the panel sits open.
  property double nowMs: Date.now()

  onSettingsChanged: syncAssignments()
  Component.onCompleted: syncAssignments()

  function syncAssignments() {
    assignments = settings && settings.assignments ? settings.assignments : ({})
  }

  readonly property var catalog: {
    var rows = snapshot && Array.isArray(snapshot.catalog) ? snapshot.catalog : []
    return rows.length > 0 ? rows : [
      { id: "codex", name: "Codex", defaultView: "subs" },
      { id: "grok", name: "Grok", defaultView: "subs" },
      { id: "claude", name: "Claude Code", defaultView: "subs" },
      { id: "opencode", name: "OpenCode", defaultView: "subs" },
      { id: "openai-api", name: "OpenAI API", defaultView: "apis" },
      { id: "xai-api", name: "xAI API", defaultView: "apis" },
      { id: "claude-api", name: "Claude API", defaultView: "apis" },
      { id: "openrouter", name: "OpenRouter", defaultView: "apis" },
      { id: "cerebras", name: "Cerebras", defaultView: "apis" }
    ]
  }
  readonly property var allProviders: snapshot && Array.isArray(snapshot.providers) ? snapshot.providers : []
  readonly property var viewProviders: {
    var rows = []
    for (var i = 0; i < allProviders.length; i++)
      if (assignmentFor(allProviders[i].id) === activeView) rows.push(allProviders[i])
    return rows
  }

  // The bar icon lights up when anything shown here is nearly out, in either
  // view, so a low balance is seen without opening APIs.
  readonly property bool alarming: {
    for (var i = 0; i < allProviders.length; i++) {
      var p = allProviders[i]
      if (assignmentFor(p.id) === "hidden") continue
      var window = bindingWindow(p)
      if (window && window.percent >= 0.9) return true
      if (balanceAlarming(p.balance)) return true
    }
    return false
  }

  function pathFromUrl(url) {
    var value = String(url || "")
    if (value.indexOf("file://") === 0) return decodeURIComponent(value.substring(7))
    return value
  }

  function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)) }
  function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }

  // -------------------------------------------------------------- the cursor
  //
  // The keyboard walks everything on the page that does something, one row at
  // a time: the hero's buttons, the view tabs, then each provider with a
  // breakdown to open, or the view choices while in settings. Up and down
  // change rows, left and right move along one. Hovering moves the same
  // cursor, so only one thing is lit.

  readonly property var assignmentChoices: [
    { id: "subs", label: "Subs" },
    { id: "apis", label: "APIs" },
    { id: "hidden", label: "Hide" }
  ]

  readonly property var keyRows: {
    var rows = [[{ kind: "refresh", index: 0 }, { kind: "settings", index: 0 }]]
    if (settingsMode) {
      for (var c = 0; c < catalog.length; c++) {
        var choices = []
        for (var a = 0; a < assignmentChoices.length; a++)
          choices.push({ kind: "assign", index: c * assignmentChoices.length + a })
        rows.push(choices)
      }
      return rows
    }
    rows.push([{ kind: "view", index: 0 }, { kind: "view", index: 1 }])
    for (var i = 0; i < viewProviders.length; i++)
      if (hasBreakdown(viewProviders[i])) rows.push([{ kind: "provider", index: i }])
    return rows
  }
  property bool cursorActive: false
  property int keyRow: 0
  property int keyColumn: 0
  readonly property var keyTarget: {
    if (!cursorActive || keyRow < 0 || keyRow >= keyRows.length) return null
    var row = keyRows[keyRow]
    return row[Math.min(keyColumn, row.length - 1)]
  }

  function hasKey(kind, index) {
    return !!keyTarget && keyTarget.kind === kind && keyTarget.index === (index || 0)
  }

  function pointAt(kind, index) {
    for (var r = 0; r < keyRows.length; r++) {
      for (var c = 0; c < keyRows[r].length; c++) {
        if (keyRows[r][c].kind === kind && keyRows[r][c].index === (index || 0)) {
          keyRow = r
          keyColumn = c
          cursorActive = true
          return
        }
      }
    }
  }

  // The first arrow only shows where the cursor is, as in the other panels.
  function moveKey(dx, dy) {
    if (keyRows.length === 0) return
    if (!cursorActive) {
      keyRow = clamp(keyRow, 0, keyRows.length - 1)
      keyColumn = 0
      cursorActive = true
      return
    }
    if (dy !== 0) {
      keyRow = clamp(keyRow + dy, 0, keyRows.length - 1)
      keyColumn = Math.min(keyColumn, keyRows[keyRow].length - 1)
    } else if (dx !== 0) {
      keyColumn = clamp(Math.min(keyColumn, keyRows[keyRow].length - 1) + dx, 0, keyRows[keyRow].length - 1)
    }
  }

  function resetKeys() {
    cursorActive = false
    keyRow = 0
    keyColumn = 0
  }

  // Nothing picked means Enter refreshes, which is what it has always done here.
  function activateSelection() {
    var target = keyTarget
    if (!target) refreshEverything(true)
    else if (target.kind === "refresh") refreshEverything(true)
    else if (target.kind === "settings") settingsMode ? showUsage() : openSettings()
    else if (target.kind === "view") selectView(target.index === 1 ? "apis" : "subs")
    else if (target.kind === "provider") toggleExpanded(viewProviders[target.index])
    else if (target.kind === "assign") {
      var count = assignmentChoices.length
      setAssignment(catalog[Math.floor(target.index / count)].id, assignmentChoices[target.index % count].id)
    }
  }

  // Keeps whatever the cursor lands on inside the scrolled view.
  function revealItem(item) {
    if (!item || !column || !panelFlick || !panelFlick.interactive) return
    var top = item.mapToItem(column, 0, 0).y
    var margin = Style.space(12)
    if (top - margin < panelFlick.contentY)
      panelFlick.contentY = Math.max(0, top - margin)
    else if (top + item.height + margin > panelFlick.contentY + panelFlick.height)
      panelFlick.contentY = Math.min(panelFlick.contentHeight - panelFlick.height, top + item.height + margin - panelFlick.height)
  }

  // ------------------------------------------------------------------- views

  // The scanner decides each provider's starting view; empty Omarchy records
  // start hidden so they don't fill the page with blank sections.
  function defaultAssignment(id) {
    for (var i = 0; i < catalog.length; i++) {
      if (catalog[i].id === id && catalog[i].defaultView) return String(catalog[i].defaultView)
    }
    return "hidden"
  }

  function assignmentFor(id) {
    var value = assignments && assignments[id] !== undefined ? String(assignments[id]) : defaultAssignment(id)
    if (value === "hidden" || value === "apis" || value === "subs") return value
    return defaultAssignment(id)
  }

  // A choice takes at once and lands in this widget's shell.json entry.
  function setAssignment(id, view) {
    var next = {}
    for (var key in assignments) next[key] = assignments[key]
    next[id] = view
    assignments = next
    if (!bar || !bar.shell || typeof bar.shell.updateEntryInline !== "function") return
    var entry = { id: moduleName }
    for (var k in settings) if (k !== "id") entry[k] = settings[k]
    entry.assignments = next
    bar.shell.updateEntryInline(moduleName, entry)
  }

  function openSettings() {
    settingsMode = true
    if (panelFlick) panelFlick.contentY = 0
    root.open()
  }

  function showUsage() {
    settingsMode = false
    if (panelFlick) panelFlick.contentY = 0
  }

  function selectView(name) {
    settingsMode = false
    activeView = name === "apis" ? "apis" : "subs"
    if (panelFlick) panelFlick.contentY = 0
  }

  function toggleExpanded(p) {
    if (!p || !hasBreakdown(p)) return
    var next = {}
    for (var key in expanded) next[key] = expanded[key]
    next[p.id] = !next[p.id]
    expanded = next
  }

  // ---------------------------------------------------------------- snapshot

  function refreshNow(force) {
    if (scanner.running) {
      rescanPending = true
      return
    }
    refreshing = true
    scanner.command = force
      ? ["python3", scannerPath, "--force-refresh"]
      : ["python3", scannerPath]
    scanner.running = true
  }

  // Omarchy's collectors for every provider the scanner doesn't handle itself.
  // Skipping those keeps the two from probing the same limits endpoints, which
  // Anthropic answers with 429s if asked too often. The kinds match Agents:
  // "limits" reuses transcript scans, "force" ignores every cache.
  function updateOmarchyRecords(kind) {
    if (omarchyUpdate.running) {
      if (kind === "force" || pendingOmarchyUpdate === "") pendingOmarchyUpdate = kind
      return
    }
    var command = ["omarchy-agent-usage-update"]
    if (kind === "force") command.push("--force")
    if (kind === "limits") command.push("--limits-only")
    var collectedHere = ["cerebras", "claude", "codex", "grok", "opencode", "openrouter"]
    for (var i = 0; i < collectedHere.length; i++) command.push("--except", collectedHere[i])
    omarchyUpdate.command = command
    omarchyUpdate.running = true
  }

  function refreshEverything(force) {
    refreshNow(force)
    updateOmarchyRecords(force ? "force" : "limits")
  }

  function applySnapshot(text) {
    try {
      var data = JSON.parse(String(text || "{}"))
      if (data && data.views) snapshot = data
    } catch (e) {
      console.warn("ghost.ai-usage", "Ignoring unreadable scanner output; keeping the last snapshot.", e)
    }
  }

  // ------------------------------------------------------------------ limits

  // Collectors spell windows differently ("Session (5-hour)", "5h window",
  // "30m window", "30-day"); all of them land on the same few titles.
  function windowTitle(label) {
    var text = String(label || "").toLowerCase()
    if (text.indexOf("month") >= 0 || text.indexOf("30-day") >= 0) return "Monthly"
    if (text.indexOf("week") >= 0 || text.indexOf("7-day") >= 0 || text.indexOf("seven") >= 0) return "Weekly"
    if (text.indexOf("session") >= 0 || text.indexOf("rolling") >= 0
        || /\d+\s*-?\s*h(our)?\b/.test(text) || /\d+\s*-?\s*m(in(ute)?s?)?\b/.test(text)) return "Session"
    var plain = String(label || "").replace(/\s*\(.*\)\s*/, "").trim()
    return plain === "" ? "Limit" : plain
  }

  // A window past its reset has rolled over, whatever the last check said.
  function limitWindows(p) {
    if (!p) return []
    var out = []
    var list = p.limits || []
    for (var i = 0; i < list.length; i++) {
      var entry = list[i] || {}
      var percent = Number(entry.percent)
      if (!(percent >= 0)) continue
      var reset = new Date(String(entry.resetsAt || "")).getTime()
      var expired = isFinite(reset) && reset <= nowMs
      out.push({
        title: String(entry.title || windowTitle(entry.label)),
        percent: expired ? 0 : percent,
        resetAt: expired ? "" : String(entry.resetsAt || "")
      })
    }
    return out
  }

  // A model-scoped window ("Fable Weekly") runs on the same clock as the window
  // it's named for, so it's a marker on that row rather than a row of its own.
  // One with nothing to attach to still gets its own row.
  function scopedPart(title) {
    var match = String(title || "").match(/^(.+) (Session|Weekly|Monthly)$/)
    return match ? { model: match[1], window: match[2] } : null
  }

  function displayWindows(p) {
    var windows = limitWindows(p)
    var out = []
    var byTitle = {}
    for (var i = 0; i < windows.length; i++) {
      if (scopedPart(windows[i].title)) continue
      windows[i].scoped = []
      out.push(windows[i])
      byTitle[windows[i].title] = windows[i]
    }
    for (var j = 0; j < windows.length; j++) {
      var part = scopedPart(windows[j].title)
      if (!part) continue
      var base = byTitle[part.window]
      if (base) {
        base.scoped.push({ title: part.model, percent: windows[j].percent })
      } else {
        windows[j].scoped = []
        out.push(windows[j])
      }
    }
    return out
  }

  function bindingWindow(p) {
    var windows = limitWindows(p)
    var best = null
    for (var i = 0; i < windows.length; i++)
      if (!best || windows[i].percent > best.percent) best = windows[i]
    return best
  }

  function resetMsFor(w) {
    if (!w || w.resetAt === "") return -1
    var ms = new Date(w.resetAt).getTime()
    return isFinite(ms) ? ms - nowMs : -1
  }

  function formatDuration(ms) {
    if (!(ms > 0)) return "now"
    var minutes = Math.floor(ms / 60000)
    var hours = Math.floor(minutes / 60)
    var days = Math.floor(hours / 24)
    if (days > 0) return days + "d " + (hours % 24) + "h"
    if (hours > 0) return hours + "h " + (minutes % 60) + "m"
    return Math.max(1, minutes) + "m"
  }

  function percentText(percent) {
    return Commons.I18n.formatNumber(Math.round(percent * 100)) + "%"
  }

  // ----------------------------------------------------------------- balance

  function balanceAlarming(b) {
    return !!b && Number(b.funded) > 0 && Number(b.remaining) / Number(b.funded) <= 0.1
  }

  function formatMoney(value, currency) {
    var amount = Number(value)
    if (!isFinite(amount)) amount = 0
    var code = String(currency || "USD").toUpperCase()
    var prefix = code === "USD" ? "$" : code === "EUR" ? "€" : code === "GBP" ? "£" : code + " "
    return prefix + Commons.I18n.formatNumber(amount, 2)
  }

  function balanceDetailText(b) {
    if (!b || !(Number(b.funded) > 0)) return ""
    return formatMoney(b.spent, b.currency) + " spent of " + formatMoney(b.funded, b.currency)
      + (b.estimated ? " · estimated" : "")
  }

  // ---------------------------------------------------------------- provider

  function planLabel(p) {
    var tier = String(p && p.tierLabel || "")
    return tier === "" ? "" : tier.charAt(0).toUpperCase() + tier.slice(1)
  }

  // Help text alone isn't a problem: an unconfigured Omarchy provider always
  // carries setup help. It only speaks up beside a status or numbers gone stale.
  function noteText(p) {
    if (!p) return ""
    var status = String(p.usageStatusText || "")
    if (status === "" && p.limitsStale !== true) return ""
    return String(p.authHelpText || status)
  }

  function hasNumbers(p) {
    return !!p && (limitWindows(p).length > 0 || !!p.balance)
  }

  function needsSignIn(p) {
    var status = String(p && p.usageStatusText || "")
    return status === "Sign-in expired" || status === "Waiting for auth"
  }

  function iconFor(p) {
    var id = p ? String(p.id) : "opencode"
    if (id === "grok" || id === "xai-api") return Qt.resolvedUrl("assets/xai.png")
    if (id === "openai-api" || id === "codex") return Qt.resolvedUrl("assets/openai.png")
    if (id === "openrouter") return Qt.resolvedUrl("assets/openrouter.svg")
    if (id === "claude" || id === "claude-api") return Qt.resolvedUrl("assets/claude.svg")
    if (id === "opencode" || id === "cerebras") return Qt.resolvedUrl("assets/" + id + ".svg")
    // Everything else wears the mark Omarchy ships for it, so a provider added
    // later needs nothing here. ProviderIcon falls back to the bar glyph.
    return "file://" + root.omarchyPath + "/shell/plugins/agents/assets/" + id + ".svg"
  }

  // ---------------------------------------------------------------- tokens

  function formatTokenCount(n) {
    var value = Number(n || 0)
    if (value >= 1e9) return Commons.I18n.formatNumber(value / 1e9, 1) + "B"
    if (value >= 1e6) return Commons.I18n.formatNumber(value / 1e6, 1) + "M"
    if (value >= 1e3) return Commons.I18n.formatNumber(value / 1e3, 1) + "K"
    return Commons.I18n.formatNumber(Math.round(value))
  }

  function dayNumbers(p) {
    var days = p ? (p.recentDays || []) : []
    var out = []
    var any = false
    for (var i = 0; i < days.length; i++) {
      var tokens = Number(days[i].messageCount || 0)
      if (tokens > 0) any = true
      out.push({ date: String(days[i].date || ""), tokens: tokens })
    }
    return any ? out : []
  }

  function modelRows(p) {
    var usage = p ? (p.modelUsage || {}) : {}
    var rows = []
    for (var id in usage) {
      var bucket = usage[id] || {}
      var input = Number(bucket.inputTokens || 0)
      var output = Number(bucket.outputTokens || 0)
      var cache = Number(bucket.cacheReadInputTokens || 0) + Number(bucket.cacheCreationInputTokens || 0)
      rows.push({ id: String(id), name: friendlyModelName(id), total: input + output + cache, input: input, output: output, cache: cache })
    }
    rows.sort(function(a, b) { return b.total - a.total })
    return rows
  }

  function hasBreakdown(p) {
    return dayNumbers(p).length > 0 || modelRows(p).length > 0
  }

  function modelWordCase(word) {
    if (word === "gpt") return "GPT"
    if (word === "deepseek") return "DeepSeek"
    return word.charAt(0).toUpperCase() + word.slice(1)
  }

  // Ids arrive hyphenated with the version split across segments
  // (`claude-opus-4-8`, `gpt-5.6-sol`, `anthropic/claude-opus-5.5`). Rejoin the
  // numeric run into one version and title-case the words around it.
  function friendlyModelName(id) {
    var name = String(id || "").replace(/^[^/]+\//, "").replace(/^claude-/, "").replace(/-\d{8}$/, "")
    var parts = name.split("-")
    var words = []
    var version = []
    for (var i = 0; i < parts.length; i++) {
      if (parts[i] === "") continue
      if (/^\d/.test(parts[i])) {
        version.push(parts[i])
        continue
      }
      if (version.length > 0) {
        words.push(version.join("."))
        version = []
      }
      words.push(modelWordCase(parts[i]))
    }
    if (version.length > 0) words.push(version.join("."))
    return words.length > 0 ? words.join(" ") : String(id || "")
  }

  function todayDate() {
    var now = new Date(nowMs)
    return now.getFullYear()
      + "-" + String(now.getMonth() + 1).padStart(2, "0")
      + "-" + String(now.getDate()).padStart(2, "0")
  }

  function dayName(date, format) {
    var parsed = new Date(String(date || "") + "T00:00:00")
    if (isNaN(parsed.getTime())) return String(date || "")
    return Qt.locale(Commons.I18n.formatLocale).dayName([7, 1, 2, 3, 4, 5, 6][parsed.getDay()], format)
  }

  // ----------------------------------------------------------------- summary
  //
  // The hero's line rotates through what the active view adds up to. The
  // scanner's own providers overlap: OpenCode's history contains the Codex and
  // Grok tokens routed through it, and xAI API repeats Grok's. Taking the largest
  // count per day and per model counts each of those once. Omarchy's records read
  // each agent's own history, so they add on top.

  readonly property var summaryPhrases: {
    var week = 0
    var today = 0
    var byDay = {}
    var byModel = {}
    var money = {}
    var todayKey = todayDate()
    function tally(map, key, tokens, additive) {
      map[key] = additive ? (map[key] || 0) + tokens : Math.max(map[key] || 0, tokens)
    }
    // Overlapping providers first, so the additive ones land on their maximum.
    var ordered = viewProviders.filter(function(p) { return p.source !== "omarchy" })
      .concat(viewProviders.filter(function(p) { return p.source === "omarchy" }))
    for (var i = 0; i < ordered.length; i++) {
      var p = ordered[i]
      var additive = p.source === "omarchy"
      var days = dayNumbers(p)
      for (var d = 0; d < days.length; d++) tally(byDay, days[d].date, days[d].tokens, additive)
      var models = modelRows(p)
      for (var m = 0; m < models.length; m++) tally(byModel, models[m].name, models[m].total, additive)
      if (p.balance) {
        var code = String(p.balance.currency || "USD")
        money[code] = (money[code] || 0) + Number(p.balance.remaining || 0)
      }
    }
    for (var date in byDay) week += byDay[date]
    today = byDay[todayKey] || 0

    var phrases = []
    for (var currency in money) phrases.push(formatMoney(money[currency], currency) + " credits left")
    if (week > 0) phrases.push(formatTokenCount(week) + " tokens this week")
    if (today > 0) phrases.push(formatTokenCount(today) + " tokens today")
    var topModel = ""
    for (var model in byModel) if (topModel === "" || byModel[model] > byModel[topModel]) topModel = model
    if (topModel !== "" && byModel[topModel] > 0) phrases.push("Mostly " + topModel)
    var busiest = ""
    for (var day in byDay) if (busiest === "" || byDay[day] > byDay[busiest]) busiest = day
    if (busiest !== "" && byDay[busiest] > 0) phrases.push("Busiest on " + dayName(busiest, Locale.LongFormat))
    return phrases
  }
  property int phraseIndex: 0
  // Every snapshot rebuilds the phrases. Indexing the live list would swap the
  // line on each one, so the hero holds what it shows until the next fade.
  property string shownPhrase: ""
  readonly property string heroPhrase: settingsMode
    ? "Choose where each one shows"
    : (shownPhrase !== "" ? shownPhrase : (activeView === "apis" ? "API spend" : "Subscriptions"))

  function showPhrase() {
    var n = summaryPhrases.length
    shownPhrase = n > 0 ? summaryPhrases[phraseIndex % n] : ""
  }

  onSummaryPhrasesChanged: if (shownPhrase === "" || summaryPhrases.length <= 1) showPhrase()
  onActiveViewChanged: {
    phraseIndex = 0
    showPhrase()
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onOpenedChanged: {
    if (!opened) {
      settingsMode = false
      return
    }
    resetKeys()
    nowMs = Date.now()
    if (panelFlick) panelFlick.contentY = 0
    refreshEverything(false)
    Qt.callLater(function() { if (panel.loadedContent) panel.loadedContent.forceActiveFocus() })
  }

  Process {
    id: scanner
    running: false
    command: []
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applySnapshot(text)
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: if (text.trim() !== "") console.warn("ghost.ai-usage", text.trim())
    }
    onExited: {
      root.refreshing = false
      if (root.rescanPending) {
        root.rescanPending = false
        root.refreshNow(false)
      }
    }
  }

  Process {
    id: omarchyUpdate
    running: false
    command: []
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: if (text.trim() !== "") console.warn("ghost.ai-usage", text.trim())
    }
    // The records are on disk now; the scanner is what brings them to the panel.
    onExited: {
      root.refreshNow(false)
      if (root.pendingOmarchyUpdate !== "") {
        var kind = root.pendingOmarchyUpdate
        root.pendingOmarchyUpdate = ""
        root.updateOmarchyRecords(kind)
      }
    }
  }

  Timer {
    interval: root.refreshIntervalSec * 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refreshNow(false)
  }

  // Same pace as Agents' default: the collectors walk transcripts on disk.
  Timer {
    interval: 900000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.updateOmarchyRecords("normal")
  }

  Timer {
    interval: 30000
    running: root.opened
    repeat: true
    onTriggered: root.nowMs = Date.now()
  }

  Timer {
    interval: 2800
    running: root.opened && root.summaryPhrases.length > 1 && !root.settingsMode
    repeat: true
    onTriggered: phraseSwap.restart()
  }

  SequentialAnimation {
    id: phraseSwap
    PropertyAnimation {
      target: root.hero; property: "metaOpacity"
      to: 0.0; duration: Style.duration(150); easing.type: Easing.OutCubic
    }
    ScriptAction {
      script: {
        root.phraseIndex = (root.phraseIndex + 1) % Math.max(1, root.summaryPhrases.length)
        root.showPhrase()
      }
    }
    PropertyAnimation {
      target: root.hero; property: "metaOpacity"
      to: 1.0; duration: Style.duration(200); easing.type: Easing.OutCubic
    }
  }

  ShellIpc {
    target: root.ipcTarget
    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() }
    function refresh(): string { root.refreshEverything(true); return "ok" }
    function settings(): string { root.openSettings(); return "ok" }
    function subs(): string { root.selectView("subs"); root.open(); return "ok" }
    function apis(): string { root.selectView("apis"); root.open(); return "ok" }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰚩"
    tooltipText: "AI usage"
    active: root.alarming
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.MiddleButton) root.refreshEverything(true)
      else if (buttonCode === Qt.RightButton) root.selectView(root.activeView === "subs" ? "apis" : "subs")
      else root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: panel.loadedContent
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(panel.loadedContentHeight, Style.space(860))

    content: PanelKeyCatcher {
      id: keyCatcher
      property alias panelFlick: panelFlick
      property alias hero: hero
      property alias column: column
      implicitHeight: column.implicitHeight
      anchors.fill: parent

      onMoveRequested: function(dx, dy) { root.moveKey(dx, dy) }
      onActivateRequested: root.activateSelection()
      onCloseRequested: root.settingsMode ? root.showUsage() : root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(t) {
        if (t === "r" || t === "R") root.refreshEverything(true)
        else if (t === "s" || t === "S") root.selectView("subs")
        else if (t === "a" || t === "A") root.selectView("apis")
        else if (t === ",") root.settingsMode ? root.showUsage() : root.openSettings()
      }

      Flickable {
        id: panelFlick
        // Reaches a little into the panel's padding on the left, with the
        // content shifted back, so the box around a lit mark isn't clipped
        // where it overhangs the content's edge.
        readonly property real overhang: Style.space(8)
        anchors.fill: parent
        anchors.leftMargin: -overhang
        contentWidth: width
        contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        interactive: contentHeight > height
        ScrollBar.vertical: ScrollBar {
          id: panelScroll
          policy: ScrollBar.AsNeeded
        }

        Column {
          id: column
          x: LayoutMirroring.enabled ? (panelFlick.interactive ? panelScroll.width + Style.space(6) : 0) : panelFlick.overhang
          // When the panel scrolls, the bar gets its own strip rather than
          // sitting on top of the right-aligned numbers.
          width: panelFlick.width - panelFlick.overhang - (panelFlick.interactive ? panelScroll.width + Style.space(6) : 0)
          spacing: Style.space(16)

          PanelHero {
            id: hero
            width: parent.width
            title: "AI Usage"
            meta: root.heroPhrase
            foreground: root.foreground
            fontFamily: root.fontFamily

            iconComponent: Component {
              Text {
                textFormat: Text.PlainText
                text: button.text
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.display
              }
            }

            trailingControl: Component {
              Row {
                spacing: Style.space(6)

                HeroButton {
                  hasCursor: root.hasKey("refresh")
                  spinning: root.refreshing && root.opened
                  onHovered: root.pointAt("refresh")
                  glyph: "󰑐"
                  tooltip: "Refresh (r)"
                  onClicked: root.refreshEverything(true)
                }

                HeroButton {
                  hasCursor: root.hasKey("settings")
                  onHovered: root.pointAt("settings")
                  glyph: root.settingsMode ? "󰅖" : "󰒓"
                  tooltip: root.settingsMode ? "Back to usage (,)" : "Choose where each one shows (,)"
                  onClicked: root.settingsMode ? root.showUsage() : root.openSettings()
                }
              }
            }
          }

          Row {
            visible: !root.settingsMode
            spacing: Style.space(14)

            TextLink {
              text: "Subs"
              fontSize: Style.font.bodySmall
              current: root.activeView === "subs"
              picked: root.hasKey("view", 0)
              tooltip: "Subscription limits (s)"
              onHovered: root.pointAt("view", 0)
              onClicked: root.selectView("subs")
            }

            TextLink {
              text: "APIs"
              fontSize: Style.font.bodySmall
              current: root.activeView === "apis"
              picked: root.hasKey("view", 1)
              tooltip: "API balances and spend (a)"
              onHovered: root.pointAt("view", 1)
              onClicked: root.selectView("apis")
            }
          }

          Text {
            visible: !root.settingsMode && root.viewProviders.length === 0
            width: parent.width
            topPadding: Style.space(8)
            textFormat: Text.PlainText
            text: root.refreshing ? "Loading usage…" : "Nothing in this view yet."
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            horizontalAlignment: Text.AlignHCenter
          }

          Repeater {
            model: root.settingsMode ? [] : root.viewProviders

            ProviderSection {
              required property var modelData
              required property int index
              width: column.width
              provider: modelData
              providerIndex: index
            }
          }

          PanelSeparator {
            visible: root.settingsMode
            foreground: root.foreground
          }

          Repeater {
            model: root.settingsMode ? root.catalog : []

            AssignmentRow {
              required property var modelData
              required property int index
              width: column.width
              provider: modelData
              rowIndex: index
            }
          }
        }
      }
    }
  }

  // One provider: its mark, name, and plan, then its limits and balance. Its
  // token history opens under the header.
  component ProviderSection: Column {
    id: section
    property var provider: null
    property int providerIndex: -1
    readonly property var windows: root.displayWindows(provider)
    readonly property var balance: provider ? (provider.balance || null) : null
    readonly property bool expandable: root.hasBreakdown(provider)
    readonly property bool isExpanded: !!provider && root.expanded[provider.id] === true
    readonly property var days: isExpanded ? root.dayNumbers(provider) : []
    readonly property var models: isExpanded ? root.modelRows(provider) : []
    // Nothing else to say means the reason gets the line; with numbers kept on
    // show it's only the mark beside the name.
    readonly property bool noteAsLine: !root.hasNumbers(provider) && root.noteText(provider) !== ""
    spacing: Style.space(16)

    PanelSeparator { foreground: root.foreground }

    Item {
      id: sectionHead
      width: parent.width
      implicitHeight: Math.max(sectionMark.height, sectionName.implicitHeight)
      readonly property bool lit: root.hasKey("provider", section.providerIndex)
      onLitChanged: if (lit) root.revealItem(sectionHead)

      MouseArea {
        anchors.fill: parent
        enabled: section.expandable
        hoverEnabled: true
        cursorShape: section.expandable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onEntered: root.pointAt("provider", section.providerIndex)
        onClicked: root.toggleExpanded(section.provider)
      }

      // Only the mark is lit, as in Agents.
      CursorSurface {
        anchors.fill: sectionMark
        anchors.margins: -Style.space(5)
        z: -1
        hasCursor: sectionHead.lit
        foreground: root.foreground
      }

      ProviderIcon {
        id: sectionMark
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        provider: section.provider
      }

      Text {
        id: sectionName
        anchors.left: sectionMark.right
        anchors.leftMargin: Style.space(10)
        anchors.verticalCenter: parent.verticalCenter
        textFormat: Text.PlainText
        text: section.provider ? section.provider.name : ""
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        font.bold: true
      }

      UsageNote {
        anchors.left: sectionName.right
        anchors.leftMargin: Style.space(8)
        anchors.verticalCenter: sectionName.verticalCenter
        visible: !section.noteAsLine && message !== ""
        message: root.noteText(section.provider)
      }

      Text {
        id: sectionChevron
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        visible: section.expandable
        textFormat: Text.PlainText
        text: section.isExpanded ? "󰅀" : "󰅂"
        color: sectionHead.lit ? Commons.Color.accent : root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
      }

      Text {
        anchors.right: section.expandable ? sectionChevron.left : parent.right
        anchors.rightMargin: section.expandable ? Style.space(8) : 0
        anchors.verticalCenter: parent.verticalCenter
        textFormat: Text.PlainText
        text: root.planLabel(section.provider)
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }
    }

    Text {
      visible: section.noteAsLine
      width: parent.width
      textFormat: Text.PlainText
      text: root.noteText(section.provider)
      color: root.needsSignIn(section.provider) ? root.urgent : root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
    }

    Column {
      visible: section.windows.length > 0
      width: parent.width
      spacing: Style.space(12)

      Repeater {
        model: section.windows

        CompactLimit {
          required property var modelData
          width: section.width
          window: modelData
        }
      }
    }

    // The meter shows what is left, not what is used: a prepaid account drains
    // toward empty rather than filling toward a cap.
    Column {
      visible: !!section.balance
      width: parent.width
      spacing: Style.space(6)

      MeterRow {
        width: parent.width
        title: "Balance"
        value: section.balance && Number(section.balance.funded) > 0
          ? Number(section.balance.remaining) / Number(section.balance.funded)
          : -1
        alarming: root.balanceAlarming(section.balance)
        trailing: section.balance ? root.formatMoney(section.balance.remaining, section.balance.currency) : ""
        trailingColor: alarming ? root.urgent : root.dim
      }

      Text {
        visible: text !== ""
        width: parent.width
        textFormat: Text.PlainText
        text: root.balanceDetailText(section.balance)
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }
    }

    Column {
      visible: section.isExpanded && section.days.length > 0
      width: parent.width
      spacing: Style.space(8)

      PanelSectionHeader {
        text: "TOKENS BY DAY"
        foreground: root.foreground
        fontFamily: root.fontFamily
      }

      Repeater {
        model: section.days

        MeterRow {
          required property var modelData
          readonly property bool today: modelData.date === root.todayDate()
          width: section.width
          title: today ? "Today" : root.dayName(modelData.date, Locale.ShortFormat)
          titleColor: today ? root.foreground : root.dim
          value: {
            var peak = 1
            for (var i = 0; i < section.days.length; i++) peak = Math.max(peak, section.days[i].tokens)
            return modelData.tokens / peak
          }
          fillColor: today ? root.foreground : root.alpha(root.foreground, 0.55)
          trailing: root.formatTokenCount(modelData.tokens)
          trailingColor: today ? root.foreground : root.dim
        }
      }
    }

    Column {
      visible: section.isExpanded && section.models.length > 0
      width: parent.width
      spacing: Style.space(4)

      PanelSectionHeader {
        bottomPadding: Style.space(4)
        text: "TOKENS BY MODEL"
        foreground: root.foreground
        fontFamily: root.fontFamily
      }

      Repeater {
        model: section.models

        ModelRow {
          required property var modelData
          width: section.width
          row: modelData
          share: modelData.total / Math.max(1, section.models[0].total)
        }
      }
    }
  }

  // Where one provider shows: its mark and name, then the three choices.
  component AssignmentRow: Item {
    id: assignment
    property var provider: null
    property int rowIndex: -1
    readonly property string current: provider ? root.assignmentFor(provider.id) : ""
    implicitHeight: Math.max(assignmentMark.height, assignmentName.implicitHeight)

    ProviderIcon {
      id: assignmentMark
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      provider: assignment.provider
    }

    Text {
      id: assignmentName
      anchors.left: assignmentMark.right
      anchors.leftMargin: Style.space(10)
      anchors.verticalCenter: parent.verticalCenter
      textFormat: Text.PlainText
      text: assignment.provider ? assignment.provider.name : ""
      color: assignment.current === "hidden" ? root.dim : root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.body
    }

    Row {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      spacing: Style.space(12)

      Repeater {
        model: root.assignmentChoices

        TextLink {
          required property var modelData
          required property int index
          readonly property int keyIndex: assignment.rowIndex * root.assignmentChoices.length + index
          text: modelData.label
          current: assignment.current === modelData.id
          picked: root.hasKey("assign", keyIndex)
          onHovered: root.pointAt("assign", keyIndex)
          onClicked: root.setAssignment(assignment.provider.id, modelData.id)
        }
      }
    }
  }

  // A provider's mark, falling back to the bar glyph when the asset is missing.
  component ProviderIcon: Item {
    id: mark
    property var provider: null
    property real size: Style.font.heading
    width: size
    height: size

    Image {
      id: markImage
      anchors.fill: parent
      source: root.iconFor(mark.provider)
      sourceSize.width: mark.size * 2
      sourceSize.height: mark.size * 2
      fillMode: Image.PreserveAspectFit
    }

    Text {
      anchors.centerIn: parent
      visible: markImage.status !== Image.Ready
      textFormat: Text.PlainText
      text: button.text
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: mark.size
    }
  }

  // The tinted square in the hero's corner.
  component HeroButton: Rectangle {
    id: heroButton
    signal clicked()
    signal hovered()
    property string glyph: ""
    property string tooltip: ""
    property bool hasCursor: false
    property bool spinning: false
    implicitWidth: Style.space(34)
    implicitHeight: implicitWidth
    radius: Style.cornerRadius
    // The cursor needs more than a shade deeper to read on a tinted square.
    color: root.alpha(Commons.Color.accent, hasCursor ? 0.3 : 0.12)
    border.width: hasCursor ? Math.max(1, Style.hoverBorderWidth) : 0
    border.color: Commons.Color.accent
    onHasCursorChanged: if (hasCursor) root.revealItem(heroButton)

    Text {
      id: heroGlyph
      anchors.centerIn: parent
      textFormat: Text.PlainText
      text: heroButton.glyph
      color: Commons.Color.accent
      font.family: root.fontFamily
      font.pixelSize: Style.font.heading

      RotationAnimation on rotation {
        running: heroButton.spinning
        loops: Animation.Infinite
        from: 0
        to: 360
        duration: 1000
        onRunningChanged: if (!running) heroGlyph.rotation = 0
      }
    }

    MouseArea {
      id: heroMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onEntered: heroButton.hovered()
      onClicked: heroButton.clicked()
    }

    PanelToolTip {
      visible: heroMouse.containsMouse
      text: heroButton.tooltip
    }
  }

  // A plain-text control: dim until hovered or picked, accent when it's the
  // current choice. Stands in for bordered buttons, which pile up here.
  component TextLink: Text {
    id: link
    signal clicked()
    signal hovered()
    property bool current: false
    property bool picked: false
    property string tooltip: ""
    property real fontSize: Style.font.caption
    readonly property bool hot: linkMouse.containsMouse || picked
    onPickedChanged: if (picked) root.revealItem(link)
    textFormat: Text.PlainText
    color: current ? Commons.Color.accent : (hot ? root.foreground : root.dim)
    font.family: root.fontFamily
    font.pixelSize: fontSize
    font.bold: current
    font.underline: hot

    MouseArea {
      id: linkMouse
      anchors.fill: parent
      anchors.margins: -Style.space(4)
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onEntered: link.hovered()
      onClicked: link.clicked()
    }

    PanelToolTip {
      visible: link.tooltip !== "" && linkMouse.containsMouse
      text: link.tooltip
    }
  }

  // A mark beside the name when the numbers aren't current, with why on hover.
  component UsageNote: Text {
    id: noteMark
    property string message: ""
    text: "󰋽"
    textFormat: Text.PlainText
    color: root.dim
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption

    HoverHandler { id: noteHover }

    PanelToolTip {
      visible: noteHover.hovered && noteMark.visible
      // Capped through implicitWidth, which the tooltip centers itself by.
      implicitWidth: Math.min(implicitContentWidth + leftPadding + rightPadding, Style.space(320))
      text: noteMark.message
    }
  }

  // One line per limit window: title, meter, and time to reset, with the exact
  // percentage in the tooltip. A window that never resets, like an account cap,
  // shows its percentage instead. A model-scoped allowance on the same clock is
  // a marker on this row's meter, named in the tooltip.
  component CompactLimit: MeterRow {
    id: compact
    property var window: null
    readonly property var scoped: window && window.scoped ? window.scoped : []
    readonly property real resetMs: root.resetMsFor(window)
    title: window ? window.title : ""
    value: window ? window.percent : -1
    alarming: !!window && window.percent >= 0.9
    markers: scoped
    trailing: resetMs > 0 ? root.formatDuration(resetMs) : (window ? root.percentText(window.percent) : "")

    HoverHandler { id: compactHover }

    PanelToolTip {
      visible: compactHover.hovered && !!compact.window
      text: {
        if (!compact.window) return ""
        var line = compact.window.title + ": " + root.percentText(compact.window.percent) + " used"
        if (compact.resetMs > 0) line += ", resets in " + root.formatDuration(compact.resetMs)
        var lines = [line]
        for (var i = 0; i < compact.scoped.length; i++)
          lines.push(compact.scoped[i].title + ": " + root.percentText(compact.scoped[i].percent) + " of its own allowance")
        return lines.join("\n")
      }
    }
  }

  // Title, meter, and a fixed-width value, so every meter ends in the same place.
  component MeterRow: Item {
    id: meterRow
    property string title: ""
    property color titleColor: root.foreground
    property real value: -1
    property bool alarming: false
    property var markers: []
    property color fillColor: root.foreground
    property string trailing: ""
    property color trailingColor: root.dim
    implicitHeight: Math.max(rowTitle.implicitHeight, rowValue.implicitHeight)

    Text {
      id: rowTitle
      width: parent.width * 0.3
      anchors.verticalCenter: parent.verticalCenter
      textFormat: Text.PlainText
      text: meterRow.title
      color: meterRow.titleColor
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      elide: Text.ElideRight
    }

    Meter {
      anchors.left: rowTitle.right
      anchors.right: rowValue.left
      anchors.rightMargin: Style.space(20)
      anchors.verticalCenter: parent.verticalCenter
      value: meterRow.value
      alarming: meterRow.alarming
      fillColor: meterRow.fillColor
      markers: meterRow.markers
    }

    TextMetrics {
      id: rowValueMetrics
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      text: "00h 00m"
    }

    Text {
      id: rowValue
      width: Math.ceil(rowValueMetrics.advanceWidth)
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      textFormat: Text.PlainText
      horizontalAlignment: Text.AlignRight
      text: meterRow.trailing
      color: meterRow.trailingColor
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
    }
  }

  // A model's share of the provider's tokens, as a soft fill behind its name.
  component ModelRow: Item {
    id: modelRow
    property var row: null
    property real share: 0
    implicitHeight: modelName.implicitHeight + Style.space(8)

    HoverHandler { id: modelHover }

    PanelToolTip {
      visible: modelHover.hovered && !!modelRow.row
      text: modelRow.row
        ? modelRow.row.id + "\n"
          + root.formatTokenCount(modelRow.row.input) + " in · "
          + root.formatTokenCount(modelRow.row.output) + " out · "
          + root.formatTokenCount(modelRow.row.cache) + " cache"
        : ""
    }

    Rectangle {
      anchors.fill: parent
      radius: Style.cornerRadius
      color: root.alpha(root.foreground, 0.05)
    }

    Rectangle {
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      width: parent.width * root.clamp(modelRow.share, 0, 1)
      radius: Style.cornerRadius
      color: root.alpha(root.foreground, 0.12)
    }

    Text {
      id: modelName
      anchors.left: parent.left
      anchors.leftMargin: Style.space(8)
      anchors.right: modelTokens.left
      anchors.rightMargin: Style.space(8)
      anchors.verticalCenter: parent.verticalCenter
      textFormat: Text.PlainText
      text: modelRow.row ? modelRow.row.name : ""
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      elide: Text.ElideRight
    }

    Text {
      id: modelTokens
      anchors.right: parent.right
      anchors.rightMargin: Style.space(8)
      anchors.verticalCenter: parent.verticalCenter
      textFormat: Text.PlainText
      text: modelRow.row ? root.formatTokenCount(modelRow.row.total) : ""
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
    }
  }

  // Rounded track. Other allowances on the same clock are ticks across it.
  component Meter: Item {
    id: meter
    property real value: -1
    property bool alarming: false
    property color fillColor: root.foreground
    property real thickness: Math.max(Style.space(4), Math.round(Style.spacing.controlHeight * 0.14))
    property var markers: []
    implicitHeight: thickness

    Rectangle {
      id: meterTrack
      anchors.fill: parent
      radius: height / 2
      color: root.track
    }

    Rectangle {
      anchors.left: meterTrack.left
      anchors.verticalCenter: meterTrack.verticalCenter
      height: meterTrack.height
      radius: meterTrack.radius
      width: meterTrack.width * root.clamp(meter.value, 0, 1)
      color: meter.alarming ? root.urgent : meter.fillColor

      Behavior on width {
        NumberAnimation { duration: Style.duration(160); easing.type: Easing.OutCubic }
      }
    }

    Repeater {
      model: meter.markers

      Rectangle {
        required property var modelData
        width: Math.max(2, Math.round(meter.thickness * 0.5))
        height: meter.thickness * 2.5
        radius: width / 2
        anchors.verticalCenter: meterTrack.verticalCenter
        // Explicit x doesn't mirror, so the tick measures from the end the
        // fill grows from.
        readonly property real along: root.clamp(meterTrack.width * root.clamp(Number(modelData.percent), 0, 1) - width / 2, 0, meterTrack.width - width)
        x: LayoutMirroring.enabled ? meterTrack.width - width - along : along
        color: meter.alarming ? root.urgent : root.foreground
      }
    }
  }
}

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "ghost.ai-usage"

  property bool popupOpen: false
  property int cacheBust: 5
  property bool settingsMode: false
  property string activeView: String(settings && settings.defaultView ? settings.defaultView : "subs")
  property string selectedProviderId: ""
  property bool refreshing: false
  property string settingsStatusText: ""
  property double nowMs: Date.now()
  property var snapshot: ({ schemaVersion: 1, catalog: [], providers: [], views: { subs: [], apis: [] } })
  property var draftAssignments: ({})

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color urgent: bar ? bar.urgent : Color.urgent
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property color surface: Color.popups.background
  readonly property color track: Style.selectedFillFor(foreground, Color.accent)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property int refreshIntervalSec: Math.max(30, Number(settings && settings.refreshIntervalSec ? settings.refreshIntervalSec : 300))
  readonly property string scannerPath: pathFromUrl(Qt.resolvedUrl("scripts/ai_usage.py"))
  readonly property var catalog: {
    var rows = snapshot && snapshot.catalog ? snapshot.catalog : []
    return Array.isArray(rows) ? rows : []
  }
  readonly property var allProviders: {
    var rows = snapshot && snapshot.providers ? snapshot.providers : []
    return Array.isArray(rows) ? rows : []
  }
  readonly property var viewProviders: {
    var rows = []
    for (var i = 0; i < allProviders.length; i++) {
      var item = allProviders[i]
      if (assignmentFor(item.id) === activeView) rows.push(item)
    }
    return rows
  }
  readonly property int providerIndex: {
    for (var i = 0; i < viewProviders.length; i++)
      if (String(viewProviders[i].id) === selectedProviderId) return i
    return 0
  }
  readonly property var provider: viewProviders.length > 0 ? viewProviders[providerIndex] : null
  readonly property var limits: limitWindows(provider)
  readonly property var models: modelRows(provider)
  readonly property var headline: bindingWindow(provider)
  readonly property var balance: provider && provider.balance ? provider.balance : null
  readonly property bool balanceAlarming: !!balance && Number(balance.funded) > 0
    && Number(balance.remaining) / Number(balance.funded) <= 0.1
  readonly property bool alarming: (!!headline && headline.percent >= 0.9) || balanceAlarming

  function pathFromUrl(url) {
    var value = String(url || "")
    if (value.indexOf("file://") === 0) return decodeURIComponent(value.substring(7))
    return value
  }

  function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)) }
  function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }

  function open() { popupOpen = true }
  function close() { popupOpen = false; settingsMode = false }
  function toggle() { popupOpen = !popupOpen }

  function defaultAssignment(id) {
    if (id === "openai-api" || id === "xai-api" || id === "openrouter" || id === "claude-api") return "apis"
    return "subs"
  }

  function assignmentFor(id) {
    var map = settings && settings.assignments ? settings.assignments : {}
    var value = map && map[id] !== undefined ? String(map[id]) : defaultAssignment(id)
    if (value === "hidden" || value === "apis" || value === "subs") return value
    return defaultAssignment(id)
  }

  function openSettings() {
    var next = {}
    var rows = catalog.length > 0 ? catalog : [
      { id: "codex", name: "Codex" },
      { id: "grok", name: "Grok" },
      { id: "claude", name: "Claude Code" },
      { id: "opencode", name: "OpenCode" },
      { id: "openai-api", name: "OpenAI API" },
      { id: "xai-api", name: "xAI API" },
      { id: "claude-api", name: "Claude API" },
      { id: "openrouter", name: "OpenRouter" }
    ]
    for (var i = 0; i < rows.length; i++) next[rows[i].id] = assignmentFor(rows[i].id)
    draftAssignments = next
    settingsStatusText = ""
    settingsMode = true
    popupOpen = true
  }

  function showUsage() {
    settingsMode = false
    settingsStatusText = ""
  }

  function setDraftAssignment(id, view) {
    var next = {}
    var source = draftAssignments || {}
    for (var key in source) next[key] = source[key]
    next[id] = view
    draftAssignments = next
  }

  function canPersistSettings() {
    return !!(bar && bar.shell && typeof bar.shell.updateEntryInline === "function")
  }

  function saveSettings() {
    var next = {
      refreshIntervalSec: refreshIntervalSec,
      defaultView: activeView,
      assignments: draftAssignments
    }
    root.settings = next
    if (canPersistSettings()) {
      bar.shell.updateEntryInline(root.moduleName, next)
      settingsStatusText = "Saved to shell.json"
    } else {
      settingsStatusText = "Saved for this session"
    }
    settingsMode = false
    if (viewProviders.length > 0) selectedProviderId = String(viewProviders[0].id || "")
  }

  function selectView(name) {
    settingsMode = false
    activeView = name === "apis" ? "apis" : "subs"
    if (viewProviders.length > 0) selectedProviderId = String(viewProviders[0].id || "")
  }

  function selectProvider(index) {
    if (viewProviders.length === 0) return
    var wrapped = ((index % viewProviders.length) + viewProviders.length) % viewProviders.length
    selectedProviderId = String(viewProviders[wrapped].id || "")
  }

  function refreshNow(force) {
    if (scanner.running) return
    refreshing = true
    scanner.command = force
      ? ["python3", scannerPath, "--force-refresh"]
      : ["python3", scannerPath]
    scanner.running = true
  }

  function applySnapshot(text) {
    try {
      var data = JSON.parse(String(text || "{}"))
      if (!data || !data.views) return
      snapshot = data
      if (viewProviders.length > 0 && selectedProviderId === "")
        selectedProviderId = String(viewProviders[0].id || "")
    } catch (e) {
      console.warn("ghost.ai-usage", e)
    }
  }

  function formatTokenCount(n) {
    var value = Number(n || 0)
    if (value >= 1e9) return (value / 1e9).toFixed(1) + "B"
    if (value >= 1e6) return (value / 1e6).toFixed(1) + "M"
    if (value >= 1e3) return (value / 1e3).toFixed(1) + "K"
    return String(Math.round(value))
  }

  function formatMoney(value, currency) {
    var amount = Number(value)
    if (!isFinite(amount)) amount = 0
    var prefix = String(currency || "USD").toUpperCase() === "USD" ? "$" : String(currency || "") + " "
    return prefix + amount.toFixed(2)
  }

  function windowTitle(label) {
    var text = String(label || "").toLowerCase()
    if (text.indexOf("month") >= 0) return "Monthly"
    if (text.indexOf("week") >= 0 || text.indexOf("7-day") >= 0) return "Weekly"
    if (text.indexOf("session") >= 0 || text.indexOf("5h") >= 0 || text.indexOf("rolling") >= 0) return "Session"
    var plain = String(label || "").replace(/\s*\(.*\)\s*/, "").trim()
    return plain === "" ? "Limit" : plain
  }

  function limitWindows(p) {
    if (!p) return []
    var out = []
    var list = p.limits || []
    for (var i = 0; i < list.length; i++) {
      var entry = list[i] || {}
      var percent = Number(entry.percent)
      if (percent >= 0)
        out.push({
          title: String(entry.title || windowTitle(entry.label)),
          percent: percent,
          resetAt: String(entry.resetsAt || "")
        })
    }
    return out
  }

  function bindingWindow(p) {
    var windows = limitWindows(p)
    var best = null
    for (var i = 0; i < windows.length; i++) {
      if (!best || windows[i].percent > best.percent) best = windows[i]
    }
    return best
  }

  function resetMsFor(w) {
    if (!w || w.resetAt === "") return -1
    var ms = new Date(w.resetAt).getTime()
    return isFinite(ms) ? ms - root.nowMs : -1
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

  function heroMeta(p) {
    if (!p) return ""
    if (String(p.usageStatusText || "") !== "") return p.usageStatusText
    var tier = String(p.tierLabel || "")
    if (tier === "") return activeView === "apis" ? "API" : "Subscription"
    return tier.charAt(0).toUpperCase() + tier.slice(1)
  }

  function todayDate() {
    var now = new Date(root.nowMs)
    return now.getFullYear()
      + "-" + String(now.getMonth() + 1).padStart(2, "0")
      + "-" + String(now.getDate()).padStart(2, "0")
  }

  function dayName(date) {
    var parsed = new Date(String(date || "") + "T00:00:00")
    if (isNaN(parsed.getTime())) return String(date || "")
    return ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][parsed.getDay()]
  }

  function weekPeak(p) {
    var days = p ? (p.recentDays || []) : []
    var peak = 0
    for (var i = 0; i < days.length; i++) peak = Math.max(peak, Number(days[i].messageCount || 0))
    return peak
  }

  function modelRows(p) {
    var usageByModel = p ? (p.modelUsage || {}) : {}
    var rows = []
    for (var id in usageByModel) {
      var bucket = usageByModel[id] || {}
      var input = Number(bucket.inputTokens || 0)
      var output = Number(bucket.outputTokens || 0)
      var cacheRead = Number(bucket.cacheReadInputTokens || 0)
      var cacheWrite = Number(bucket.cacheCreationInputTokens || 0)
      rows.push({
        name: String(id),
        total: input + output + cacheRead + cacheWrite,
        input: input,
        output: output,
        cacheRead: cacheRead,
        cacheWrite: cacheWrite
      })
    }
    rows.sort(function(a, b) { return b.total - a.total })
    return rows
  }

  function iconFor(p) {
    var id = p ? String(p.id) : "opencode"
    if (id === "grok" || id === "xai-api") return Qt.resolvedUrl("assets/xai.png")
    if (id === "openai-api" || id === "codex") return Qt.resolvedUrl("assets/openai.png")
    if (id === "openrouter") return Qt.resolvedUrl("assets/openrouter.svg")
    if (id === "claude" || id === "claude-api") return Qt.resolvedUrl("assets/claude.svg")
    return Qt.resolvedUrl("assets/" + id + ".svg")
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onPopupOpenChanged: if (popupOpen) {
    nowMs = Date.now()
    refreshNow()
    Qt.callLater(function() { if (keyCatcher) keyCatcher.forceActiveFocus() })
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
      onStreamFinished: function(text) {
        if (text && text.trim() !== "") console.warn("ghost.ai-usage", text.trim())
      }
    }
    onExited: root.refreshing = false
  }

  Timer {
    interval: root.refreshIntervalSec * 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refreshNow()
  }

  Timer {
    interval: 30000
    running: root.popupOpen
    repeat: true
    onTriggered: root.nowMs = Date.now()
  }

  IpcHandler {
    target: "ghost.ai-usage"
    function open(): string { root.open(); return "ok" }
    function close(): string { root.close(); return "ok" }
    function toggle(): string { root.toggle(); return "ok" }
    function refresh(): string { root.refreshNow(true); return "ok" }
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
      if (buttonCode === Qt.MiddleButton) root.refreshNow(true)
      else if (buttonCode === Qt.RightButton) root.selectView(root.activeView === "subs" ? "apis" : "subs")
      else root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.popupOpen
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(640))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent

      onMoveRequested: function(dx, dy) {
        if (dx !== 0) root.selectProvider(root.providerIndex + dx)
        if (dy !== 0)
          panelFlick.contentY = root.clamp(panelFlick.contentY + dy * Style.space(56), 0,
                                           Math.max(0, panelFlick.contentHeight - panelFlick.height))
      }
      onActivateRequested: root.refreshNow(true)
      onCloseRequested: root.close()
      onTextKey: function(t) {
        if (t === "r" || t === "R") root.refreshNow(true)
        if (t === "s" || t === "S") root.settingsMode ? root.saveSettings() : root.selectView("subs")
        if (t === "a" || t === "A") root.selectView("apis")
        if (t === ",") root.openSettings()
      }

      Flickable {
        id: panelFlick
        anchors.fill: parent
        contentWidth: width
        contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        interactive: contentHeight > height
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
          id: column
          width: panelFlick.width
          spacing: Style.space(12)

          Item {
            visible: root.settingsMode
            width: parent.width
            implicitHeight: settingsTitle.implicitHeight

            Text {
              id: settingsTitle
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              text: "Settings"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.title
              font.bold: true
            }

            Button {
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              text: ""
              iconText: "\uf013"
              tooltipText: "Back to usage"
              bordered: false
              selected: true
              foreground: root.foreground
              fontFamily: root.fontFamily
              onClicked: root.showUsage()
            }
          }

          Column {
            visible: root.settingsMode
            width: parent.width
            spacing: Style.space(10)

            PanelSectionHeader {
              width: parent.width
              text: "SHOW IN"
              foreground: root.foreground
              fontFamily: root.fontFamily
            }

            Repeater {
              model: root.catalog.length > 0 ? root.catalog : [
                { id: "codex", name: "Codex" },
                { id: "grok", name: "Grok" },
                { id: "claude", name: "Claude Code" },
                { id: "opencode", name: "OpenCode" },
                { id: "openai-api", name: "OpenAI API" },
                { id: "xai-api", name: "xAI API" },
                { id: "claude-api", name: "Claude API" },
                { id: "openrouter", name: "OpenRouter" }
              ]

              Column {
                id: providerRow
                required property var modelData
                readonly property string providerId: String(modelData.id)
                width: parent.width
                spacing: Style.space(6)

                Text {
                  text: modelData.name
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                }

                Row {
                  width: parent.width
                  spacing: Style.spacing.sm
                  Repeater {
                    model: [
                      { id: "subs", label: "Subs" },
                      { id: "apis", label: "APIs" },
                      { id: "hidden", label: "Hide" }
                    ]
                    Button {
                      required property var modelData
                      width: (parent.width - Style.spacing.sm * 2) / 3
                      text: modelData.label
                      selected: String(root.draftAssignments[providerRow.providerId] || root.defaultAssignment(providerRow.providerId)) === modelData.id
                      bordered: true
                      foreground: root.foreground
                      fontFamily: root.fontFamily
                      fontSize: Style.font.caption
                      onClicked: root.setDraftAssignment(providerRow.providerId, modelData.id)
                    }
                  }
                }
              }
            }

            Button {
              width: parent.width
              text: "Save"
              bordered: true
              foreground: root.foreground
              fontFamily: root.fontFamily
              fontSize: Style.font.bodySmall
              onClicked: root.saveSettings()
            }

            Text {
              visible: root.settingsStatusText !== ""
              width: parent.width
              text: root.settingsStatusText
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              horizontalAlignment: Text.AlignHCenter
            }
          }

          PanelHero {
            visible: !root.settingsMode && !!root.provider
            width: parent.width
            title: root.provider ? root.provider.name : ""
            meta: root.heroMeta(root.provider)
            foreground: root.foreground
            fontFamily: root.fontFamily
            iconComponent: Component {
              Image {
                width: Style.font.display
                height: Style.font.display
                source: root.iconFor(root.provider)
                sourceSize.width: Style.font.display * 2
                sourceSize.height: Style.font.display * 2
                fillMode: Image.PreserveAspectFit
              }
            }
            trailingControl: Component {
              Button {
                text: ""
                iconText: "\uf013"
                tooltipText: "Settings"
                bordered: false
                selected: root.settingsMode
                foreground: root.foreground
                fontFamily: root.fontFamily
                onClicked: root.openSettings()
              }
            }
          }

          ButtonGroup {
            visible: !root.settingsMode
            width: parent.width
            foreground: root.foreground
            fontFamily: root.fontFamily
            fontSize: Style.font.bodySmall
            focusable: false
            value: root.activeView
            options: [
              { value: "subs", label: "Subs" },
              { value: "apis", label: "APIs" }
            ]
            onChanged: function(value) { root.selectView(value) }
          }

          Text {
            visible: !root.settingsMode && root.viewProviders.length === 0
            width: parent.width
            topPadding: Style.space(24)
            text: root.refreshing ? "Loading usage…" : "No usage yet."
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            horizontalAlignment: Text.AlignHCenter
          }

          Row {
            id: providerSwitch
            visible: !root.settingsMode && root.viewProviders.length > 1
            width: parent.width
            spacing: Style.spacing.md
            readonly property real cellWidth: root.viewProviders.length > 0
              ? (width - spacing * (root.viewProviders.length - 1)) / root.viewProviders.length
              : 0

            Repeater {
              model: root.viewProviders
              Button {
                required property var modelData
                required property int index
                width: providerSwitch.cellWidth
                text: modelData.name
                selected: index === root.providerIndex
                bordered: true
                foreground: root.foreground
                fontFamily: root.fontFamily
                fontSize: Style.font.bodySmall
                onClicked: root.selectProvider(index)
              }
            }
          }

          BorderSurface {
            visible: !root.settingsMode && !!root.provider && String(root.provider.usageStatusText || "") !== ""
            width: parent.width
            implicitHeight: statusText.implicitHeight + Style.spacing.xl * 2
            color: root.alpha(root.urgent, 0.10)
            borderSpec: Border.flat(root.alpha(root.urgent, 0.35), 1)
            radius: Style.cornerRadius
            Text {
              id: statusText
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              anchors.leftMargin: Style.space(12)
              anchors.rightMargin: Style.space(12)
              text: root.provider ? String(root.provider.authHelpText || root.provider.usageStatusText) : ""
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              wrapMode: Text.WordWrap
            }
          }

          PanelSeparator {
            visible: !root.settingsMode && (balanceSection.visible || limitsSection.visible)
            foreground: root.foreground
          }

          Column {
            id: balanceSection
            visible: !root.settingsMode && !!root.balance
            width: parent.width
            spacing: Style.space(10)
            readonly property real ratio: root.balance && Number(root.balance.funded) > 0
              ? root.clamp(Number(root.balance.remaining) / Number(root.balance.funded), 0, 1)
              : -1

            PanelSectionHeader {
              width: parent.width
              text: "BALANCE"
              foreground: root.foreground
              fontFamily: root.fontFamily
            }

            Item {
              width: parent.width
              implicitHeight: Math.max(balanceLabel.implicitHeight, balanceValue.implicitHeight)
              Text {
                id: balanceLabel
                text: "Prepaid credits"
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
              }
              Text {
                id: balanceValue
                text: root.balance ? root.formatMoney(root.balance.remaining, root.balance.currency) : ""
                color: root.balanceAlarming ? root.urgent : root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
              }
            }

            Meter {
              visible: balanceSection.ratio >= 0
              width: parent.width
              value: 1 - Math.max(0, balanceSection.ratio)
              alarming: root.balanceAlarming
            }

            Text {
              visible: !!root.balance && Number(root.balance.funded) > 0
              width: parent.width
              text: root.balance
                ? root.formatMoney(root.balance.spent, root.balance.currency)
                  + " spent of " + root.formatMoney(root.balance.funded, root.balance.currency)
                  + (root.balance.estimated ? " · estimated" : "")
                : ""
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }
          }

          Column {
            id: limitsSection
            visible: !root.settingsMode && root.limits.length > 0
            width: parent.width
            spacing: Style.space(10)

            PanelSectionHeader {
              text: "LIMITS"
              foreground: root.foreground
              fontFamily: root.fontFamily
            }

            Repeater {
              model: root.limits
              LimitRow {
                required property var modelData
                width: limitsSection.width
                window: modelData
              }
            }
          }

          PanelSeparator {
            visible: !root.settingsMode && usageSection.visible
            foreground: root.foreground
          }

          Column {
            id: usageSection
            visible: !root.settingsMode && !!root.provider && root.provider.recentDays && root.provider.recentDays.length > 0
            width: parent.width
            spacing: Style.spacing.md
            readonly property var days: root.provider ? (root.provider.recentDays || []) : []
            readonly property real peak: Math.max(1, root.weekPeak(root.provider))

            PanelSectionHeader {
              width: parent.width
              text: "TOKENS BY DAY"
              foreground: root.foreground
              fontFamily: root.fontFamily
            }

            Repeater {
              model: usageSection.days
              DayRow {
                required property var modelData
                width: usageSection.width
                day: modelData
                ratio: Number(modelData.messageCount || 0) / usageSection.peak
                today: String(modelData.date || "") === root.todayDate()
              }
            }
          }

          PanelSeparator {
            visible: !root.settingsMode && modelSection.visible
            foreground: root.foreground
          }

          Column {
            id: modelSection
            visible: !root.settingsMode && root.models.length > 0
            width: parent.width
            spacing: Style.spacing.md

            PanelSectionHeader {
              width: parent.width
              text: "TOKENS BY MODEL"
              foreground: root.foreground
              fontFamily: root.fontFamily
            }

            Repeater {
              model: root.models
              ModelRow {
                required property var modelData
                width: modelSection.width
                row: modelData
                share: modelData.total / Math.max(1, root.models[0].total)
              }
            }
          }

          Text {
            width: parent.width
            text: root.refreshing ? "Refreshing…" : "settings · s subs · a apis · r refresh · esc close"
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            horizontalAlignment: Text.AlignHCenter
          }
        }
      }
    }
  }

  component LimitRow: Column {
    id: limitRow
    property var window: null
    readonly property bool alarming: window && window.percent >= 0.9
    spacing: Style.space(6)

    Item {
      width: parent.width
      implicitHeight: Math.max(limitLabel.implicitHeight, limitValue.implicitHeight)
      Text {
        id: limitLabel
        text: limitRow.window ? limitRow.window.title : ""
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        elide: Text.ElideRight
        anchors.left: parent.left
        anchors.right: limitValue.left
        anchors.rightMargin: Style.spacing.sm
        anchors.verticalCenter: parent.verticalCenter
      }
      Text {
        id: limitValue
        text: limitRow.window && limitRow.window.percent >= 0
          ? Math.round(limitRow.window.percent * 100) + "%"
          : "—"
        color: limitRow.alarming ? root.urgent : root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    Meter {
      width: parent.width
      value: limitRow.window ? limitRow.window.percent : -1
      alarming: limitRow.alarming
    }

    Text {
      width: parent.width
      text: {
        var remainingMs = root.resetMsFor(limitRow.window)
        return remainingMs > 0 ? "Resets in " + root.formatDuration(remainingMs) : ""
      }
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
    }
  }

  component Meter: Item {
    id: meter
    property real value: -1
    property bool alarming: false
    property real thickness: Math.max(Style.space(4), Math.round(Style.spacing.controlHeight * 0.14))
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
      color: meter.alarming ? root.urgent : root.foreground
      Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    }
  }

  component DayRow: Item {
    id: dayRow
    property var day: null
    property real ratio: 0
    property bool today: false
    implicitHeight: Math.max(dayLabel.implicitHeight, dayValue.implicitHeight) + Style.spacing.sm

    Text {
      id: dayLabel
      text: dayRow.today ? "Today" : root.dayName(dayRow.day ? dayRow.day.date : "")
      color: dayRow.today ? root.foreground : root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: dayRow.today
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      width: Style.space(52)
    }

    Rectangle {
      anchors.left: dayLabel.right
      anchors.right: dayValue.left
      anchors.leftMargin: Style.space(8)
      anchors.rightMargin: Style.space(10)
      anchors.verticalCenter: parent.verticalCenter
      height: Math.max(Style.space(4), Math.round(Style.spacing.controlHeight * 0.14))
      radius: height / 2
      color: root.track
      Rectangle {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height
        radius: parent.radius
        width: parent.width * root.clamp(dayRow.ratio, 0, 1)
        color: dayRow.today ? root.foreground : root.alpha(root.foreground, 0.55)
      }
    }

    Text {
      id: dayValue
      text: root.formatTokenCount(dayRow.day ? Number(dayRow.day.messageCount || 0) : 0)
      color: dayRow.today ? root.foreground : root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: true
      horizontalAlignment: Text.AlignRight
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      width: Style.space(52)
    }
  }

  component ModelRow: Item {
    id: modelRow
    property var row: null
    property real share: 0
    implicitHeight: modelName.implicitHeight + Style.spacing.lg

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
      color: root.alpha(root.foreground, 0.14)
    }
    Text {
      id: modelName
      text: modelRow.row ? modelRow.row.name : ""
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      elide: Text.ElideRight
      anchors.left: parent.left
      anchors.leftMargin: Style.space(8)
      anchors.right: modelTokens.left
      anchors.rightMargin: Style.space(8)
      anchors.verticalCenter: parent.verticalCenter
    }
    Text {
      id: modelTokens
      text: modelRow.row ? root.formatTokenCount(modelRow.row.total) : ""
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      font.bold: true
      anchors.right: parent.right
      anchors.rightMargin: Style.space(8)
      anchors.verticalCenter: parent.verticalCenter
    }
  }
}

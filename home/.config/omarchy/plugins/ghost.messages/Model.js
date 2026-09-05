var APPS = [
  {
    id: "slack",
    name: "Slack",
    icon: "",
    desktop: "slack.desktop",
    classes: ["slack"],
    notificationNames: ["slack"]
  },
  {
    id: "signal",
    name: "Signal",
    icon: "󰭹",
    desktop: "signal.desktop",
    classes: ["signal"],
    notificationNames: ["signal", "signal desktop"]
  },
  {
    id: "discord",
    name: "Discord",
    icon: "",
    desktop: "vesktop.desktop",
    classes: ["vesktop"],
    notificationNames: ["discord", "vesktop"]
  }
]

function apps() {
  return APPS
}

function lower(value) {
  return String(value || "").trim().toLowerCase()
}

function appForNotification(value) {
  var name = lower(value)
  for (var i = 0; i < APPS.length; i++) {
    var aliases = APPS[i].notificationNames
    for (var j = 0; j < aliases.length; j++) {
      if (name === aliases[j]) return APPS[i]
    }
  }
  return null
}

function appForWindow(toplevel) {
  if (!toplevel) return null
  var wayland = toplevel.wayland
  var ipc = toplevel.lastIpcObject
  var className = lower(wayland && wayland.appId
    ? wayland.appId
    : (ipc ? (ipc["class"] || ipc["initialClass"]) : ""))
  for (var i = 0; i < APPS.length; i++) {
    if (APPS[i].classes.indexOf(className) !== -1) return APPS[i]
  }
  return null
}

function windowsFor(app, toplevels) {
  var result = []
  var rows = toplevels || []
  for (var i = 0; i < rows.length; i++) {
    var matched = appForWindow(rows[i])
    if (matched && matched.id === app.id) result.push(rows[i])
  }
  return result
}

function appStates(toplevels) {
  var result = []
  for (var i = 0; i < APPS.length; i++) {
    var app = APPS[i]
    var windows = windowsFor(app, toplevels)
    var urgent = false
    for (var j = 0; j < windows.length; j++) {
      if (windows[j] && windows[j].urgent === true) urgent = true
    }
    result.push({
      id: app.id,
      name: app.name,
      icon: app.icon,
      desktop: app.desktop,
      running: windows.length > 0,
      urgent: urgent,
      window: windows.length > 0 ? windows[0] : null
    })
  }
  return result
}

function parseHistory(raw) {
  try {
    var parsed = JSON.parse(String(raw || "[]"))
    return Array.isArray(parsed) ? parsed : []
  } catch (e) {
    return []
  }
}

function chatNotifications(entries) {
  var rows = entries || []
  var result = []
  for (var i = 0; i < rows.length; i++) {
    var entry = rows[i] || {}
    var app = appForNotification(entry.app)
    if (!app) continue
    result.push({
      appId: app.id,
      appName: app.name,
      icon: app.icon,
      summary: String(entry.summary || app.name),
      body: String(entry.body || ""),
      timestamp: Number(entry.timestamp || 0)
    })
  }
  result.sort(function(a, b) { return b.timestamp - a.timestamp })
  return result
}

function relativeTime(timestamp, now) {
  var elapsed = Math.max(0, Number(now || Date.now()) - Number(timestamp || 0))
  var minutes = Math.floor(elapsed / 60000)
  if (minutes < 1) return "now"
  if (minutes < 60) return minutes + "m"
  var hours = Math.floor(minutes / 60)
  if (hours < 24) return hours + "h"
  return Math.floor(hours / 24) + "d"
}

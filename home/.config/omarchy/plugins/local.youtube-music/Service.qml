import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property var shell: null
  property var manifest: null
  readonly property string pluginDir: manifest && manifest.__sourceDir ? String(manifest.__sourceDir) : ""
  readonly property string helper: pluginDir + "/ytmusic.py"
  readonly property string runtimePython: (Quickshell.env("HOME") || "") + "/.local/share/omarchy-youtube-music/venv/bin/python"

  property bool searchLoading: false
  property var searchResults: []
  property string searchQuery: ""
  property string error: ""
  property bool authenticated: false
  property bool authLoading: false
  property bool authCheckStarted: false
  property var account: ({})
  property bool contentLoading: false
  property var homeSections: []
  property var libraryItems: []
  property string libraryKind: "songs"
  property string contentTitle: ""
  property var currentContext: null
  property string contentAction: ""
  property var queue: []
  property int queueIndex: -1
  property var currentTrack: queueIndex >= 0 && queueIndex < queue.length ? queue[queueIndex] : null
  property bool running: false
  property bool playing: false
  property real position: 0
  property real duration: 0

  function checkAuth() {
    if (authProcess.running || helper === "" || pluginDir === "") return
    authCheckStarted = true
    authLoading = true
    authProcess.command = [runtimePython, helper, "auth-status"]
    authProcess.running = true
  }

  function connect(headers) {
    if (authProcess.running || !String(headers || "").trim()) return
    authLoading = true
    error = ""
    authProcess.pendingInput = JSON.stringify({ headers: String(headers) }) + "\n"
    authProcess.command = [runtimePython, helper, "auth-setup"]
    authProcess.running = true
  }

  function logout() {
    if (authProcess.running) return
    authLoading = true
    authProcess.command = [runtimePython, helper, "auth-logout"]
    authProcess.running = true
  }

  function clearAccountState() {
    account = ({})
    homeSections = []
    libraryItems = []
    contentTitle = ""
    libraryKind = "songs"
  }

  function loadHome() {
    if (!authenticated || contentProcess.running) return
    contentLoading = true
    error = ""
    contentProcess.command = [runtimePython, helper, "home"]
    contentProcess.running = true
  }

  function loadLibrary(kind) {
    if (!authenticated || contentProcess.running) return
    libraryKind = String(kind || "songs")
    contentTitle = ""
    contentLoading = true
    error = ""
    contentProcess.command = [runtimePython, helper, "library", libraryKind]
    contentProcess.running = true
  }

  function loadPlaylist(item) {
    openContext(item)
  }

  function openContext(item) {
    loadContext(item, "open")
  }

  function playContext(item, mode) {
    loadContext(item, mode || "play")
  }

  function loadContext(item, mode) {
    if (!authenticated || !item || !item.id || contentProcess.running) return
    contentLoading = true
    libraryKind = "context"
    currentContext = item
    contentAction = String(mode || "open")
    contentTitle = String(item.title || "Playlist")
    error = ""
    contentProcess.command = [
      runtimePython, helper, "context",
      String(item.kind || ""), String(item.id || ""),
      String(item.playlistId || ""), String(item.title || "YouTube Music"),
      contentAction
    ]
    contentProcess.running = true
  }

  function runSearch(query) {
    var value = String(query || "").trim()
    if (!value || searchProcess.running) return
    searchQuery = value
    searchLoading = true
    error = ""
    searchProcess.command = ["python3", helper, "search", value]
    searchProcess.running = true
  }

  function play(item, sourceItems) {
    if (!item || !item.url || actionProcess.running) return
    var items = Array.isArray(sourceItems) && sourceItems.length ? sourceItems.slice() : [item]
    var index = -1
    for (var i = 0; i < items.length; i++) if (items[i].id === item.id) { index = i; break }
    queue = items
    queueIndex = Math.max(0, index)
    position = 0
    duration = Number(item.duration) || 0
    error = ""
    actionProcess.command = ["python3", helper, "play", String(item.url), String(item.title || "YouTube Music")]
    actionProcess.running = true
  }

  function playIndex(index) {
    if (index < 0 || index >= queue.length) return
    var items = queue.slice()
    play(items[index], items)
  }

  function next() { if (queueIndex + 1 < queue.length) playIndex(queueIndex + 1) }
  function previous() { if (queueIndex > 0) playIndex(queueIndex - 1) }
  function toggle() { runAction("toggle") }
  function seek(seconds) { runAction("seek", String(Math.max(0, Number(seconds) || 0))) }
  function stop() {
    if (!stopProcess.running) {
      stopProcess.command = ["python3", helper, "stop"]
      stopProcess.running = true
    }
    running = false
    playing = false
    position = 0
  }

  function runAction(name, argument) {
    if (actionProcess.running) return
    error = ""
    actionProcess.command = ["python3", helper, name]
    if (argument !== undefined) actionProcess.command.push(argument)
    actionProcess.running = true
  }

  function refreshState() {
    if (stateProcess.running || actionProcess.running) return
    stateProcess.command = ["python3", helper, "state"]
    stateProcess.running = true
  }

  function applyState(text) {
    try {
      var state = JSON.parse(String(text || "{}"))
      running = state.running === true
      playing = state.playing === true
      position = Number(state.position) || 0
      if (Number(state.duration) > 0) duration = Number(state.duration)
      if (running && duration > 0 && position >= duration - 0.5 && queueIndex + 1 < queue.length) next()
    } catch (exception) {
    }
  }

  Timer {
    interval: 1000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.refreshState()
  }

  onHelperChanged: if (!authCheckStarted && helper !== "") checkAuth()
  Component.onCompleted: Qt.callLater(function() {
    if (!root.authCheckStarted) root.checkAuth()
  })

  Process {
    id: authProcess
    property string pendingInput: ""
    stdinEnabled: true
    onStarted: {
      if (pendingInput !== "") write(pendingInput)
      pendingInput = ""
    }
    stdout: StdioCollector { id: authOutput; waitForEnd: true }
    stderr: StdioCollector { id: authError; waitForEnd: true }
    onExited: function(code) {
      root.authLoading = false
      try {
        var response = JSON.parse(authOutput.text || "{}")
        var wasAuthenticated = root.authenticated
        root.authenticated = code === 0 && response.authenticated !== false && response.ok === true
        if (response.account) root.account = response.account
        if (wasAuthenticated && !root.authenticated) root.clearAccountState()
        if (code !== 0) root.error = response.error || String(authError.text || "YouTube Music login failed").trim()
        if (root.authenticated && root.homeSections.length === 0) root.loadHome()
      } catch (exception) {
        root.authenticated = false
        root.error = "The YouTube Music login response could not be read"
      }
    }
  }

  Process {
    id: contentProcess
    stdout: StdioCollector { id: contentOutput; waitForEnd: true }
    stderr: StdioCollector { id: contentError; waitForEnd: true }
    onExited: function(code) {
      root.contentLoading = false
      try {
        var response = JSON.parse(contentOutput.text || "{}")
        if (code !== 0 || !response.ok) {
          root.error = response.error || String(contentError.text || "YouTube Music could not be loaded").trim()
          return
        }
        if (response.sections) root.homeSections = response.sections
        if (response.items) {
          root.libraryItems = response.items
          if (response.autoplay === true && response.items.length > 0)
            root.play(response.items[0], response.items)
        }
        if (response.title) root.contentTitle = response.title
      } catch (exception) {
        root.error = "YouTube Music returned an unreadable response"
      }
    }
  }

  Process {
    id: searchProcess
    stdout: StdioCollector { id: searchOutput; waitForEnd: true }
    stderr: StdioCollector { id: searchError; waitForEnd: true }
    onExited: function(code) {
      root.searchLoading = false
      try {
        var response = JSON.parse(searchOutput.text || "{}")
        if (code === 0 && response.ok) root.searchResults = response.items || []
        else root.error = response.error || String(searchError.text || "Search failed").trim()
      } catch (exception) {
        root.error = "YouTube Music search returned an unreadable response"
      }
    }
  }

  Process {
    id: actionProcess
    stdout: StdioCollector { id: actionOutput; waitForEnd: true }
    stderr: StdioCollector { id: actionError; waitForEnd: true }
    onExited: function(code) {
      if (code !== 0) {
        try { root.error = JSON.parse(actionOutput.text || "{}").error || "Playback failed" }
        catch (exception) { root.error = String(actionError.text || "Playback failed").trim() }
      }
      root.refreshState()
    }
  }

  Process {
    id: stopProcess
    stdout: StdioCollector { waitForEnd: true }
    stderr: StdioCollector { waitForEnd: true }
    onExited: root.refreshState()
  }

  Process {
    id: stateProcess
    stdout: StdioCollector { id: stateOutput; waitForEnd: true }
    onExited: root.applyState(stateOutput.text)
  }
}

import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Commons
import qs.Ui

Item {
  id: root

  property var shell: null
  property var manifest: null
  property var service: null
  property bool opened: false
  property bool closingFromHost: false
  property string currentView: "search"
  property bool confirmSignOut: false
  readonly property color foreground: Color.foreground
  readonly property color background: Color.background
  readonly property color accent: Color.accent
  readonly property string fontFamily: Style.font.family

  function open(payload) {
    if (service && !service.authenticated && !service.authLoading) currentView = "setup"
    else if (currentView === "setup") currentView = "home"
    opened = true
    if (currentView === "search") Qt.callLater(function() { searchField.forceActiveFocus() })
  }

  function close() {
    if (service) service.stop()
    closingFromHost = true
    opened = false
    closingFromHost = false
  }

  function requestClose() {
    if (service) service.stop()
    if (shell && typeof shell.hide === "function") shell.hide("local.youtube-music")
    else close()
  }

  function status() {
    return JSON.stringify({
      opened: opened,
      authenticated: service ? service.authenticated : false,
      authLoading: service ? service.authLoading : false,
      view: currentView
    })
  }

  function formatTime(seconds) {
    var value = Math.max(0, Math.floor(Number(seconds) || 0))
    var minutes = Math.floor(value / 60)
    var remainder = value % 60
    return String(minutes) + ":" + (remainder < 10 ? "0" : "") + String(remainder)
  }

  function openLibrary(kind) {
    currentView = "library"
    confirmSignOut = false
    if (service) service.loadLibrary(kind)
  }

  function pageTitle() {
    if (currentView === "home") return "Home"
    if (currentView === "library") return service && service.contentTitle
      ? service.contentTitle : "Your Library"
    if (currentView === "queue") return "Queue"
    if (currentView === "setup") return service && service.authenticated ? "Settings" : "Connect YouTube Music"
    return "Search"
  }

  function pageSubtitle() {
    if (currentView === "home") return "Made for you"
    if (currentView === "library") return service && service.libraryKind === "history"
      ? "Recently played" : "Music saved to your account"
    if (currentView === "queue") return "What plays next"
    if (currentView === "setup") return service && service.authenticated
      ? "Account and local session" : "Bring your YouTube Music library into Omarchy"
    return "Songs, artists, albums, and playlists"
  }

  Connections {
    target: root.service
    ignoreUnknownSignals: true

    function onAuthenticatedChanged() {
      if (!root.service) return
      if (root.service.authenticated && root.currentView === "setup" && !root.confirmSignOut) {
        root.currentView = "home"
        if (root.service.homeSections.length === 0) root.service.loadHome()
      } else if (!root.service.authenticated) {
        root.currentView = "setup"
      }
    }
  }

  FloatingWindow {
    id: window
    visible: root.opened
    title: "YouTube Music"
    color: root.background
    implicitWidth: 1040
    implicitHeight: 720
    minimumSize: Qt.size(720, 520)

    onVisibleChanged: if (!visible && root.opened && !root.closingFromHost) root.requestClose()

    FocusScope {
      anchors.fill: parent
      focus: true
      Keys.onEscapePressed: root.requestClose()

      Shortcut { sequence: "Ctrl+K"; onActivated: searchField.forceActiveFocus() }
      Shortcut { sequence: "Space"; enabled: !searchField.activeFocus; onActivated: if (root.service) root.service.toggle() }
      Shortcut { sequence: "Ctrl+Right"; onActivated: if (root.service) root.service.next() }
      Shortcut { sequence: "Ctrl+Left"; onActivated: if (root.service) root.service.previous() }
      Shortcut {
        sequence: "Ctrl+Shift+S"
        context: Qt.ApplicationShortcut
        onActivated: if (root.service) root.service.stop()
      }

      Row {
        id: workspace
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: player.top
        anchors.margins: Style.space(14)
        anchors.bottomMargin: Style.space(10)
        spacing: Style.space(10)

        BorderSurface {
          width: Style.space(205)
          height: parent.height
          radius: Style.cornerRadius
          color: Style.normalFillFor(root.foreground, root.accent)
          borderSpec: Border.controlSpec("normal", root.foreground, root.accent)

          Item {
            anchors.fill: parent
            anchors.margins: Style.space(10)

            Row {
              id: brand
              width: parent.width
              height: Style.space(48)
              spacing: Style.space(9)
              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "󰗃"
                color: root.accent
                font.family: root.fontFamily
                font.pixelSize: Style.font.display
              }
              Column {
                anchors.verticalCenter: parent.verticalCenter
                Text { text: "Music"; color: root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.subtitle; font.bold: true }
                Text { text: "for YouTube"; color: Qt.darker(root.foreground, 1.4); font.family: root.fontFamily; font.pixelSize: Style.font.caption }
              }
            }

            Column {
              id: navigation
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.top: brand.bottom
              spacing: Style.space(3)

              PanelSeparator { width: parent.width; foreground: root.foreground }
              Button {
                width: parent.width
                visible: root.service && root.service.authenticated
                text: "Home"
                iconText: "󰋜"
                foreground: root.foreground
                leftAlign: true
                selected: root.currentView === "home"
                onClicked: {
                  root.currentView = "home"
                  root.confirmSignOut = false
                  if (root.service && root.service.homeSections.length === 0) root.service.loadHome()
                }
              }
              Button {
                width: parent.width
                text: "Search"
                iconText: "󰍉"
                foreground: root.foreground
                leftAlign: true
                selected: root.currentView === "search"
                onClicked: { root.currentView = "search"; root.confirmSignOut = false; searchField.forceActiveFocus() }
              }
              Button {
                width: parent.width
                text: "Queue"
                iconText: "󰐕"
                foreground: root.foreground
                leftAlign: true
                selected: root.currentView === "queue"
                onClicked: { root.currentView = "queue"; root.confirmSignOut = false }
              }

              Item { width: 1; height: Style.space(10) }
              Text {
                visible: root.service && root.service.authenticated
                width: parent.width
                text: "YOUR LIBRARY"
                color: Qt.darker(root.foreground, 1.4)
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                font.bold: true
                leftPadding: Style.space(8)
              }
              Repeater {
                model: [
                  { id: "liked", label: "Liked Songs", icon: "󰋑" },
                  { id: "songs", label: "Songs", icon: "󰎈" },
                  { id: "albums", label: "Albums", icon: "󰀥" },
                  { id: "artists", label: "Artists", icon: "󰠃" },
                  { id: "playlists", label: "Playlists", icon: "󱁐" },
                  { id: "history", label: "History", icon: "󰋚" }
                ]
                Button {
                  required property var modelData
                  visible: root.service && root.service.authenticated
                  width: navigation.width
                  text: modelData.label
                  iconText: modelData.icon
                  foreground: root.foreground
                  leftAlign: true
                  selected: root.currentView === "library" && root.service.libraryKind === modelData.id
                  onClicked: root.openLibrary(modelData.id)
                }
              }
            }

            BorderSurface {
              id: accountFooter
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.bottom: parent.bottom
              height: Style.space(62)
              radius: Style.cornerRadius
              color: accountMouse.containsMouse ? Style.hoverFillFor(root.foreground, root.accent) : "transparent"
              borderSpec: Border.controlSpec("normal", root.foreground, root.accent)

              Row {
                anchors.fill: parent
                anchors.margins: Style.space(7)
                spacing: Style.space(8)
                Rectangle {
                  width: Style.space(36)
                  height: width
                  radius: width / 2
                  color: Style.selectedFillFor(root.foreground, root.accent)
                  clip: true
                  Image {
                    anchors.fill: parent
                    source: root.service && root.service.account ? String(root.service.account.accountPhotoUrl || "") : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                  }
                  Text {
                    anchors.centerIn: parent
                    visible: !root.service || !root.service.account || !root.service.account.accountPhotoUrl
                    text: "󰀄"
                    color: root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.icon
                  }
                }
                Column {
                  width: parent.width - Style.space(48)
                  anchors.verticalCenter: parent.verticalCenter
                  Text {
                    width: parent.width
                    text: root.service && root.service.authenticated
                      ? String(root.service.account.accountName || "YouTube Music") : "Connect account"
                    color: root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.bodySmall
                    font.bold: true
                    elide: Text.ElideRight
                  }
                  Text {
                    width: parent.width
                    text: root.service && root.service.authenticated
                      ? String(root.service.account.channelHandle || "Settings") : "Unlock your library"
                    color: Qt.darker(root.foreground, 1.4)
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    elide: Text.ElideRight
                  }
                }
              }
              MouseArea {
                id: accountMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: { root.currentView = "setup"; root.confirmSignOut = false }
              }
            }
          }
        }

        Item {
          width: parent.width - Style.space(215)
          height: parent.height

          Row {
            id: header
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: Style.space(48)
            spacing: Style.space(6)

            TextField {
              id: searchField
              visible: root.currentView === "search"
              width: parent.width - closeButton.width - parent.spacing
              anchors.verticalCenter: parent.verticalCenter
              foreground: root.foreground
              placeholderText: "Search songs, artists, or albums"
              onAccepted: {
                root.currentView = "search"
                if (root.service) root.service.runSearch(text)
              }
            }
            Column {
              visible: root.currentView !== "search"
              width: parent.width - closeButton.width - parent.spacing
              anchors.verticalCenter: parent.verticalCenter
              spacing: 0
              Text { width: parent.width; text: root.pageTitle(); color: root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.title; font.bold: true; elide: Text.ElideRight }
              Text { width: parent.width; text: root.pageSubtitle(); color: Qt.darker(root.foreground, 1.4); font.family: root.fontFamily; font.pixelSize: Style.font.caption; elide: Text.ElideRight }
            }
            Button {
              id: closeButton
              anchors.verticalCenter: parent.verticalCenter
              iconText: "󰅖"
              tooltipText: "Close"
              foreground: root.foreground
              onClicked: root.requestClose()
            }
          }

          BorderSurface {
            id: errorBanner
            visible: root.service && root.service.error !== ""
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.topMargin: Style.space(5)
            height: visible ? Style.space(48) : 0
            radius: Style.cornerRadius
            color: Style.selectedFillFor(root.foreground, Color.urgent)
            borderSpec: Border.controlSpec("normal", root.foreground, Color.urgent)
            Text {
              id: errorText
              anchors.fill: parent
              anchors.margins: Style.space(6)
              text: root.service ? root.service.error : ""
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              wrapMode: Text.WordWrap
            }
          }

          ListView {
            id: results
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: errorBanner.visible ? errorBanner.bottom : header.bottom
            anchors.topMargin: Style.space(8)
            anchors.bottom: parent.bottom
            visible: root.currentView === "search"
            model: root.service ? root.service.searchResults : []
            spacing: Style.space(5)
            clip: true
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            header: Item {
              width: results.width
              height: root.service && root.service.searchLoading ? Style.space(44) : Style.space(26)
              Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: root.service && root.service.searchLoading
                  ? "Searching YouTube Music…"
                  : (root.service && root.service.searchResults.length ? "RESULTS" : "SEARCH YOUTUBE MUSIC")
                color: Qt.darker(root.foreground, 1.35)
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                font.bold: true
              }
            }

            delegate: BorderSurface {
              required property var modelData
              width: ListView.view.width
              height: Style.space(72)
              radius: Style.cornerRadius
              color: rowMouse.containsMouse ? Style.selectedFillFor(root.foreground, root.accent) : Style.normalFillFor(root.foreground, root.accent)
              borderSpec: Border.controlSpec("normal", root.foreground, root.accent)

              Row {
                anchors.fill: parent
                anchors.margins: Style.space(7)
                spacing: Style.space(10)
                Image {
                  id: resultCover
                  width: parent.height
                  height: parent.height
                  source: modelData.thumbnail || ""
                  fillMode: Image.PreserveAspectCrop
                  asynchronous: true
                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (root.service) root.service.play(modelData, root.service.searchResults)
                  }
                }
                Column {
                  id: resultDetails
                  width: parent.width - parent.height - playButton.width - Style.space(30)
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: Style.space(3)
                  Text { width: parent.width; text: modelData.title; color: root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.body; font.bold: true; elide: Text.ElideRight }
                  Text { width: parent.width; text: modelData.artist; color: Qt.darker(root.foreground, 1.35); font.family: root.fontFamily; font.pixelSize: Style.font.bodySmall; elide: Text.ElideRight }
                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (root.service) root.service.play(modelData, root.service.searchResults)
                  }
                }
                Button {
                  id: playButton
                  anchors.verticalCenter: parent.verticalCenter
                  iconText: "󰐊"
                  tooltipText: "Play"
                  foreground: root.foreground
                  onClicked: if (root.service) root.service.play(modelData, root.service.searchResults)
                }
              }
              MouseArea {
                id: rowMouse
                anchors.fill: parent
                hoverEnabled: true
                z: -1
                onDoubleClicked: if (root.service) root.service.play(modelData, root.service.searchResults)
              }
            }
          }

          Flickable {
            id: homeView
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.topMargin: Style.space(8)
            anchors.bottom: parent.bottom
            visible: root.currentView === "home"
            contentWidth: width
            contentHeight: homeContent.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            Column {
              id: homeContent
              width: parent.width
              spacing: Style.space(16)

              Text {
                width: parent.width
                text: root.service && root.service.contentLoading ? "Loading your music…" : "FOR YOU"
                color: Qt.darker(root.foreground, 1.35)
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                font.bold: true
              }

              Repeater {
                model: root.service ? root.service.homeSections : []
                Column {
                  required property var modelData
                  width: homeContent.width
                  spacing: Style.space(7)

                  Text {
                    width: parent.width
                    text: modelData.title
                    color: root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.title
                    font.bold: true
                    elide: Text.ElideRight
                  }

                  ListView {
                    id: shelfList
                    width: parent.width
                    height: Style.space(180)
                    orientation: ListView.Horizontal
                    model: modelData.items
                    spacing: Style.space(8)
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.horizontal: ScrollBar {
                      policy: shelfList.contentWidth > shelfList.width ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                    }
                    WheelHandler {
                      acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                      onWheel: function(event) {
                        var delta = event.angleDelta.x !== 0 ? event.angleDelta.x : event.angleDelta.y
                        shelfList.contentX = Math.max(0, Math.min(
                          shelfList.contentWidth - shelfList.width,
                          shelfList.contentX - delta))
                        event.accepted = true
                      }
                    }

                    delegate: BorderSurface {
                      required property var modelData
                      width: Style.space(145)
                      height: Style.space(176)
                      radius: Style.cornerRadius
                      color: shelfMouse.containsMouse ? Style.selectedFillFor(root.foreground, root.accent) : Style.normalFillFor(root.foreground, root.accent)
                      borderSpec: Border.controlSpec("normal", root.foreground, root.accent)

                      Column {
                        anchors.fill: parent
                        anchors.margins: Style.space(6)
                        spacing: Style.space(5)
                        Image { width: parent.width; height: width; source: modelData.thumbnail || ""; fillMode: Image.PreserveAspectCrop; asynchronous: true }
                        Text { width: parent.width; text: modelData.title; color: root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.bodySmall; font.bold: true; elide: Text.ElideRight }
                        Text { width: parent.width; text: modelData.artist || modelData.kind; color: Qt.darker(root.foreground, 1.35); font.family: root.fontFamily; font.pixelSize: Style.font.caption; elide: Text.ElideRight }
                      }
                      MouseArea {
                        id: shelfMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                          if (!root.service) return
                          if (modelData.kind === "track") root.service.play(modelData, [modelData])
                          else {
                            root.currentView = "library"
                            root.service.openContext(modelData)
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }

          ListView {
            id: libraryView
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.topMargin: Style.space(8)
            anchors.bottom: parent.bottom
            visible: root.currentView === "library"
            model: root.service ? root.service.libraryItems : []
            spacing: Style.space(5)
            clip: true
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            header: Column {
              width: libraryView.width
              spacing: Style.space(7)
              Text {
                width: parent.width
                text: root.service && root.service.contentTitle
                  ? root.service.contentTitle.toUpperCase()
                  : (root.service && root.service.contentLoading ? "LOADING…" : "YOUR LIBRARY")
                color: Qt.darker(root.foreground, 1.35)
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                font.bold: true
              }
              Flow {
                width: parent.width
                spacing: Style.space(5)
                visible: !root.service || root.service.libraryKind !== "context"
                Repeater {
                  model: [
                    { id: "songs", label: "Songs" },
                    { id: "liked", label: "Liked" },
                    { id: "playlists", label: "Playlists" },
                    { id: "albums", label: "Albums" },
                    { id: "artists", label: "Artists" },
                    { id: "history", label: "History" }
                  ]
                  Button {
                    required property var modelData
                    text: modelData.label
                    foreground: root.foreground
                    selected: root.service && root.service.libraryKind === modelData.id
                    onClicked: if (root.service) root.service.loadLibrary(modelData.id)
                  }
                }
              }
              Row {
                visible: root.service && root.service.libraryKind === "context"
                spacing: Style.space(6)
                Button {
                  text: "Play"
                  iconText: "󰐊"
                  foreground: root.foreground
                  selected: true
                  enabled: root.service && !root.service.contentLoading
                  onClicked: if (root.service) root.service.playContext(root.service.currentContext, "play")
                }
                Button {
                  text: "Shuffle"
                  iconText: "󰒟"
                  foreground: root.foreground
                  enabled: root.service && !root.service.contentLoading
                  onClicked: if (root.service) root.service.playContext(root.service.currentContext, "shuffle")
                }
                Button {
                  text: "Radio"
                  iconText: "󰎆"
                  foreground: root.foreground
                  enabled: root.service && !root.service.contentLoading
                  onClicked: if (root.service) root.service.playContext(root.service.currentContext, "radio")
                }
              }
              Item { width: 1; height: Style.space(4) }
            }

            delegate: BorderSurface {
              required property var modelData
              width: ListView.view.width
              height: Style.space(68)
              radius: Style.cornerRadius
              color: libraryMouse.containsMouse ? Style.selectedFillFor(root.foreground, root.accent) : Style.normalFillFor(root.foreground, root.accent)
              borderSpec: Border.controlSpec("normal", root.foreground, root.accent)
              Row {
                anchors.fill: parent
                anchors.margins: Style.space(6)
                spacing: Style.space(9)
                Image { width: parent.height; height: parent.height; source: modelData.thumbnail || ""; fillMode: Image.PreserveAspectCrop; asynchronous: true }
                Column {
                  width: parent.width - parent.height - Style.space(12)
                  anchors.verticalCenter: parent.verticalCenter
                  Text { width: parent.width; text: modelData.title; color: root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.body; font.bold: true; elide: Text.ElideRight }
                  Text { width: parent.width; text: modelData.artist || modelData.kind; color: Qt.darker(root.foreground, 1.35); font.family: root.fontFamily; font.pixelSize: Style.font.bodySmall; elide: Text.ElideRight }
                }
              }
              MouseArea {
                id: libraryMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (!root.service) return
                  if (modelData.kind === "track") root.service.play(modelData, root.service.libraryItems)
                  else root.service.openContext(modelData)
                }
              }
            }
          }

          Flickable {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.topMargin: Style.space(8)
            anchors.bottom: parent.bottom
            visible: root.currentView === "setup"
            contentWidth: width
            contentHeight: setupContent.implicitHeight
            clip: true

            Column {
              id: setupContent
              width: parent.width
              spacing: Style.space(10)

              Text { width: parent.width; text: root.service && root.service.authenticated ? "YouTube Music connected" : "Connect YouTube Music"; color: root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.title; font.bold: true }
              BorderSurface {
                visible: root.service && root.service.authenticated
                width: parent.width
                height: Style.space(86)
                radius: Style.cornerRadius
                color: Style.normalFillFor(root.foreground, root.accent)
                borderSpec: Border.controlSpec("normal", root.foreground, root.accent)
                Row {
                  anchors.fill: parent
                  anchors.margins: Style.space(10)
                  spacing: Style.space(10)
                  Rectangle {
                    width: Style.space(54)
                    height: width
                    radius: width / 2
                    color: Style.selectedFillFor(root.foreground, root.accent)
                    clip: true
                    Image {
                      anchors.fill: parent
                      source: root.service && root.service.account ? String(root.service.account.accountPhotoUrl || "") : ""
                      fillMode: Image.PreserveAspectCrop
                      asynchronous: true
                    }
                  }
                  Column {
                    width: parent.width - Style.space(64)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Style.space(3)
                    Text { width: parent.width; text: root.service ? String(root.service.account.accountName || "YouTube Music") : "YouTube Music"; color: root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.subtitle; font.bold: true; elide: Text.ElideRight }
                    Text { width: parent.width; text: root.service ? String(root.service.account.channelHandle || "Connected account") : ""; color: Qt.darker(root.foreground, 1.35); font.family: root.fontFamily; font.pixelSize: Style.font.bodySmall; elide: Text.ElideRight }
                  }
                }
              }
              Text {
                width: parent.width
                text: root.service && root.service.authenticated
                  ? "Your saved browser session is active. Personalized recommendations and library data are loaded from this account."
                  : "1. Open music.youtube.com and sign in.\n2. Open Developer Tools, then Network.\n3. Reload and select a successful POST request containing /youtubei/v1/browse.\n4. Right-click it and choose Copy > Copy as cURL.\n5. Paste the entire curl command below and connect."
                color: Qt.darker(root.foreground, 1.25)
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
                wrapMode: Text.WordWrap
              }
              Text {
                width: parent.width
                text: "Your Google password is never requested. The imported session is sent to the helper over stdin and stored locally with owner-only permissions."
                color: root.accent
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
                wrapMode: Text.WordWrap
              }
              TextArea {
                id: headersField
                visible: !root.service || !root.service.authenticated
                width: parent.width
                height: Style.space(210)
                placeholderText: "Paste the complete curl command here, not the request URL"
                wrapMode: TextEdit.WrapAnywhere
                color: root.foreground
                font.family: root.fontFamily
                background: BorderSurface {
                  color: Style.normalFillFor(root.foreground, root.accent)
                  radius: Style.cornerRadius
                  borderSpec: Border.controlSpec("normal", root.foreground, root.accent)
                }
              }
              Button {
                visible: !root.service || !root.service.authenticated
                text: root.service && root.service.authLoading ? "Connecting…" : "Connect"
                iconText: "󰌋"
                foreground: root.foreground
                selected: true
                enabled: root.service && !root.service.authLoading && headersField.text.trim() !== ""
                onClicked: {
                  if (!root.service) return
                  root.service.connect(headersField.text)
                  headersField.text = ""
                }
              }
              PanelSeparator {
                visible: root.service && root.service.authenticated
                width: parent.width
                foreground: root.foreground
              }
              Text {
                visible: root.service && root.service.authenticated
                width: parent.width
                text: "ACCOUNT"
                color: Qt.darker(root.foreground, 1.4)
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                font.bold: true
              }
              Text {
                visible: root.service && root.service.authenticated
                width: parent.width
                text: "Signing out removes the locally saved browser session. It does not sign you out of YouTube Music in your browser or alter your Google account."
                color: Qt.darker(root.foreground, 1.3)
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
                wrapMode: Text.WordWrap
              }
              Row {
                visible: root.service && root.service.authenticated
                spacing: Style.space(7)
                Button {
                  text: root.confirmSignOut ? "Confirm sign out" : "Sign out"
                  iconText: "󰍃"
                  foreground: root.foreground
                  bordered: true
                  enabled: root.service && !root.service.authLoading
                  onClicked: {
                    if (!root.confirmSignOut) {
                      root.confirmSignOut = true
                      return
                    }
                    root.confirmSignOut = false
                    root.service.logout()
                  }
                }
                Button {
                  visible: root.confirmSignOut
                  text: "Cancel"
                  foreground: root.foreground
                  onClicked: root.confirmSignOut = false
                }
              }
            }
          }

          ListView {
            id: queueList
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.topMargin: Style.space(8)
            anchors.bottom: parent.bottom
            visible: root.currentView === "queue"
            model: root.service ? root.service.queue : []
            spacing: Style.space(4)
            clip: true
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
            header: Text {
              width: queueList.width
              height: Style.space(34)
              text: "UP NEXT"
              color: Qt.darker(root.foreground, 1.35)
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
            }
            delegate: Button {
              required property var modelData
              required property int index
              width: ListView.view.width
              text: modelData.title + (modelData.artist ? "  ·  " + modelData.artist : "")
              iconText: root.service && root.service.queueIndex === index ? "󰏤" : "󰐊"
              foreground: root.foreground
              leftAlign: true
              selected: root.service && root.service.queueIndex === index
              onClicked: if (root.service) root.service.playIndex(index)
            }
          }
        }
      }

      BorderSurface {
        id: player
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Style.space(14)
        height: Style.space(108)
        radius: Style.cornerRadius
        color: Style.normalFillFor(root.foreground, root.accent)
        borderSpec: Border.controlSpec("normal", root.foreground, root.accent)

        Row {
          anchors.fill: parent
          anchors.margins: Style.space(10)
          spacing: Style.space(12)

          Image {
            width: parent.height
            height: parent.height
            source: root.service && root.service.currentTrack ? root.service.currentTrack.thumbnail : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
          }

          Column {
            width: Math.max(160, parent.width * 0.3)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(3)
            Text { width: parent.width; text: root.service && root.service.currentTrack ? root.service.currentTrack.title : "Nothing playing"; color: root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.body; font.bold: true; elide: Text.ElideRight }
            Text { width: parent.width; text: root.service && root.service.currentTrack ? root.service.currentTrack.artist : "Search for something to play"; color: root.accent; font.family: root.fontFamily; font.pixelSize: Style.font.bodySmall; elide: Text.ElideRight }
          }

          Column {
            width: Math.max(220, parent.width - Style.space(110) - Math.max(160, parent.width * 0.3) - Style.space(24))
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(8)

            Row {
              anchors.horizontalCenter: parent.horizontalCenter
              spacing: Style.space(7)
              Button { iconText: "󰒮"; foreground: root.foreground; enabled: root.service && root.service.queueIndex > 0; onClicked: root.service.previous() }
              Button { iconText: root.service && root.service.playing ? "󰏤" : "󰐊"; foreground: root.foreground; enabled: root.service && root.service.currentTrack; onClicked: root.service.toggle() }
              Button { iconText: "󰓛"; tooltipText: "Stop playback"; foreground: root.foreground; enabled: root.service && (root.service.running || root.service.currentTrack); onClicked: root.service.stop() }
              Button { iconText: "󰒭"; foreground: root.foreground; enabled: root.service && root.service.queueIndex + 1 < root.service.queue.length; onClicked: root.service.next() }
            }

            Row {
              width: parent.width
              spacing: Style.space(7)
              Text { width: Style.space(38); text: root.formatTime(root.service ? root.service.position : 0); color: root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.caption }
              Slider {
                width: parent.width - Style.space(90)
                from: 0
                to: root.service ? Math.max(1, root.service.duration) : 1
                value: root.service ? root.service.position : 0
                enabled: root.service && root.service.duration > 0
                onMoved: if (root.service) root.service.seek(value)
              }
              Text { width: Style.space(38); text: root.formatTime(root.service ? root.service.duration : 0); color: root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.caption; horizontalAlignment: Text.AlignRight }
            }
          }
        }
      }
    }
  }
}

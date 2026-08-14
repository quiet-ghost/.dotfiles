import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root
  moduleName: "ghost.opencode-service"
  ipcTarget: "ghost.opencode-service"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  property bool expanded: false
  property string pendingAction: ""
  property int pendingSessions: 0

  readonly property var snapshot: service.snapshot
  readonly property color foreground: Color.popups.text
  readonly property color dim: Color.muted
  readonly property color accent: Color.accent
  readonly property color urgent: Color.urgent
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property bool hasOwner: snapshot.identity !== null
  readonly property bool canStart: snapshot.state === "stopped"
  readonly property bool canStop: hasOwner && snapshot.state !== "stopped"
  readonly property string serviceState: snapshot && snapshot.state ? snapshot.state : "checking"
  readonly property color stateColor: serviceState === "ready" ? "#9ccfd8"
    : (serviceState === "transitioning" || serviceState === "checking") ? "#f6c177"
    : serviceState === "stopped" ? "#6e6a86"
    : "#eb6f92"

  function setExpanded(value) {
    expanded = value
    Qt.callLater(function() { if (opened) keyCatcher.forceActiveFocus() })
  }

  function requestAction(name) {
    if (service.actionRunning) return
    if (name === "start") {
      service.runAction(name)
      return
    }
    pendingAction = name
    pendingSessions = snapshot.activeSessions === null ? 0 : snapshot.activeSessions
    confirmDialog.selectedIndex = 0
  }

  function cancelAction() {
    pendingAction = ""
    Qt.callLater(function() { if (opened) keyCatcher.forceActiveFocus() })
  }

  function confirmAction() {
    var action = pendingAction
    pendingAction = ""
    service.runAction(action)
    Qt.callLater(function() { if (opened) keyCatcher.forceActiveFocus() })
  }

  function openLogs() {
    var home = Quickshell.env("HOME")
    if (!home) return
    Quickshell.execDetached(["xdg-terminal-exec", "-e", "tail", "-f",
                            home + "/.local/share/opencode/log/opencode.log"])
  }

  function tooltip() {
    var value = "OpenCode: " + Model.stateLabel(snapshot.state)
    if (snapshot.endpoint) value += " · port " + snapshot.endpoint.port
    if (snapshot.activeSessions !== null) value += " · " + snapshot.activeSessions + " active"
    return value
  }

  onOpenedChanged: {
    if (opened) {
      expanded = setting("openExpanded", false) === true
      service.refresh()
    } else {
      pendingAction = ""
      expanded = false
    }
  }

  ServiceController {
    id: service
    settings: root.settings
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: ""
    iconComponent: Component {
      Item {
        Image {
          anchors.centerIn: parent
          width: Style.space(17)
          height: width
          source: Qt.resolvedUrl("assets/opencode.svg")
          fillMode: Image.PreserveAspectFit
          smooth: true
        }
        Rectangle {
          width: Style.space(5)
          height: width
          radius: width / 2
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          anchors.rightMargin: Style.space(1)
          anchors.bottomMargin: Style.space(1)
          color: root.stateColor
          border.width: 1
          border.color: Color.background
        }
      }
    }
    tooltipText: root.tooltip()
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.MiddleButton) service.refresh()
      else root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    centerOnBar: false
    contentWidth: panel.fittedContentWidth(root.expanded ? Style.space(560) : Style.space(390))
    contentHeight: panel.fittedContentHeight(
      contentLoader.item ? contentLoader.item.implicitHeight : Style.space(320), Style.space(700))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent

      onMoveRequested: function(dx, dy) {
        if (root.pendingAction && dx !== 0)
          confirmDialog.selectedIndex = confirmDialog.selectedIndex === 0 ? 1 : 0
      }
      onActivateRequested: {
        if (!root.pendingAction) return
        if (confirmDialog.selectedIndex === 0) root.cancelAction()
        else root.confirmAction()
      }
      onCloseRequested: {
        if (root.pendingAction) root.cancelAction()
        else if (root.expanded) root.setExpanded(false)
        else root.close()
      }
      onTabRequested: function(direction) {
        if (root.pendingAction)
          confirmDialog.selectedIndex = confirmDialog.selectedIndex === 0 ? 1 : 0
        else root.switchPanel(direction)
      }
      onTextKey: function(value) {
        if (root.pendingAction) return
        var key = String(value || "").toLowerCase()
        if (key === "r") service.refresh()
        else if (key === "e") root.setExpanded(!root.expanded)
        else if (key === "l") root.openLogs()
        else if (key === "s" && root.canStart) root.requestAction("start")
      }

      Loader {
        id: contentLoader
        width: parent.width
        sourceComponent: root.expanded ? expandedContent : compactContent
      }

      ConfirmDialog {
        id: confirmDialog
        anchors.fill: parent
        opened: root.pendingAction !== ""
        z: 20
        message: {
          var action = root.pendingAction === "restart" ? "Restart" : "Stop"
          var sessions = root.pendingSessions > 0
            ? "\n" + root.pendingSessions + " active session" + (root.pendingSessions === 1 ? "" : "s") + " may be interrupted."
            : "\nConnected clients will be disconnected."
          return action + " the shared OpenCode service?" + sessions
        }
        confirmText: root.pendingAction === "restart" ? "Restart" : "Stop"
        background: Color.popups.background
        foreground: root.foreground
        selectedText: root.accent
        fontFamily: root.fontFamily
        cornerRadius: Style.cornerRadius
        onCanceled: root.cancelAction()
        onConfirmed: root.confirmAction()
      }
    }
  }

  Component {
    id: header
    Row {
      width: parent ? parent.width : 0
      spacing: Style.spacing.sm

      Text {
        width: parent.width - refreshButton.width - expandButton.width - parent.spacing * 2
        anchors.verticalCenter: parent.verticalCenter
        text: "OpenCode Service"
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.title
        font.bold: true
        elide: Text.ElideRight
      }

      Button {
        id: refreshButton
        anchors.verticalCenter: parent.verticalCenter
        text: ""
        iconText: "\uf021"
        iconSpinning: service.refreshRunning
        tooltipText: "Refresh service status"
        foreground: root.foreground
        fontFamily: root.fontFamily
        onClicked: service.refresh()
      }

      Button {
        id: expandButton
        anchors.verticalCenter: parent.verticalCenter
        text: ""
        iconText: root.expanded ? "\uf066" : "\uf065"
        tooltipText: root.expanded ? "Compact view" : "Detailed diagnostics"
        foreground: root.foreground
        fontFamily: root.fontFamily
        onClicked: root.setExpanded(!root.expanded)
      }
    }
  }

  Component {
    id: compactContent
    Column {
      width: contentLoader.width
      spacing: Style.spacing.panelGap

      Loader { width: parent.width; sourceComponent: header }

      BorderSurface {
        width: parent.width
        implicitHeight: statusColumn.implicitHeight + contentTopInset + contentBottomInset
        color: Util.alpha(root.stateColor, 0.09)
        borderSpec: Border.flat(Util.alpha(root.stateColor, 0.38), Style.normalBorderWidth)
        radius: Style.cornerRadius
        padding: Style.space(12)

        Column {
          id: statusColumn
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.margins: parent.contentLeftInset
          spacing: Style.spacing.xs

          Row {
            width: parent.width
            spacing: Style.spacing.sm
            Text {
              text: Model.stateGlyph(root.snapshot.state)
              color: root.stateColor
              font.family: root.fontFamily
              font.pixelSize: Style.font.title
            }
            Text {
              text: Model.stateLabel(root.snapshot.state)
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.title
              font.bold: true
            }
          }
          Text {
            width: parent.width
            text: Model.statusMessage(root.snapshot)
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            wrapMode: Text.WordWrap
          }
        }
      }

      Grid {
        width: parent.width
        columns: 2
        columnSpacing: Style.spacing.sm
        rowSpacing: Style.spacing.sm

        Repeater {
          model: [
            { label: "PORT", value: root.snapshot.endpoint ? String(root.snapshot.endpoint.port) : "—" },
            { label: "ACTIVE SESSIONS", value: Model.sessionsText(root.snapshot) },
            { label: "VERSION", value: Model.versionText(root.snapshot) },
            { label: "LATENCY", value: Model.latencyText(root.snapshot) }
          ]
          BorderSurface {
            required property var modelData
            width: (parent.width - parent.columnSpacing) / 2
            height: Style.space(66)
            color: Util.alpha(root.foreground, 0.045)
            borderSpec: Border.flat(Util.alpha(root.foreground, 0.08), Style.normalBorderWidth)
            radius: Style.cornerRadius

            Column {
              anchors.centerIn: parent
              spacing: Style.spacing.xs
              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: modelData.label
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
              }
              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: modelData.value
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
                font.bold: true
                elide: Text.ElideRight
              }
            }
          }
        }
      }

      Loader { width: parent.width; sourceComponent: actionRow }

      Text {
        visible: service.actionStatusText !== ""
        width: parent.width
        text: service.actionStatusText
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        wrapMode: Text.WordWrap
      }
    }
  }

  Component {
    id: expandedContent
    Column {
      width: contentLoader.width
      spacing: Style.spacing.panelGap

      Loader { width: parent.width; sourceComponent: header }
      Loader { width: parent.width; sourceComponent: compactStatus }

      PanelSectionHeader {
        width: parent.width
        text: "SERVICE IDENTITY"
        foreground: root.foreground
        fontFamily: root.fontFamily
      }

      Grid {
        width: parent.width
        columns: 2
        columnSpacing: Style.spacing.md
        rowSpacing: Style.spacing.sm
        Repeater {
          model: [
            { label: "Endpoint", value: Model.endpointText(root.snapshot) },
            { label: "Exposure", value: root.snapshot.endpoint ? root.snapshot.endpoint.exposure : "—" },
            { label: "PID", value: Model.pidText(root.snapshot) },
            { label: "Identity", value: root.snapshot.identity ? (root.snapshot.identity.matches ? "Matched" : "Mismatch") : "—" },
            { label: "Version", value: Model.versionText(root.snapshot) },
            { label: "Active sessions", value: Model.sessionsText(root.snapshot) },
            { label: "Health latency", value: Model.latencyText(root.snapshot) },
            { label: "Last success", value: Model.timeText(service.lastSuccessfulAt) }
          ]
          Item {
            required property var modelData
            width: (parent.width - parent.columnSpacing) / 2
            height: detailColumn.implicitHeight
            Column {
              id: detailColumn
              width: parent.width
              spacing: Style.spacing.xs
              Text {
                width: parent.width
                text: modelData.label.toUpperCase()
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
              }
              Text {
                width: parent.width
                text: modelData.value
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
                elide: Text.ElideMiddle
              }
            }
          }
        }
      }

      BorderSurface {
        visible: !!root.snapshot.failure
        width: parent.width
        implicitHeight: recoveryColumn.implicitHeight + contentTopInset + contentBottomInset
        color: Util.alpha(root.stateColor, 0.07)
        borderSpec: Border.flat(Util.alpha(root.stateColor, 0.28), Style.normalBorderWidth)
        radius: Style.cornerRadius
        padding: Style.space(10)
        Column {
          id: recoveryColumn
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.margins: parent.contentLeftInset
          spacing: Style.spacing.xs
          Text {
            text: root.snapshot.failure ? root.snapshot.failure.tag.toUpperCase().replace(/_/g, " ") : ""
            color: root.stateColor
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
          }
          Text {
            width: parent.width
            text: root.snapshot.failure ? root.snapshot.failure.recovery : ""
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            wrapMode: Text.WordWrap
          }
        }
      }

      PanelSeparator { width: parent.width; foreground: root.foreground }
      Loader { width: parent.width; sourceComponent: actionRow }
      Button {
        width: parent.width
        text: "Open service log"
        iconText: "\uf15c"
        bordered: true
        foreground: root.foreground
        fontFamily: root.fontFamily
        onClicked: root.openLogs()
      }
      Text {
        visible: service.actionStatusText !== ""
        width: parent.width
        text: service.actionStatusText
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        wrapMode: Text.WordWrap
      }
    }
  }

  Component {
    id: compactStatus
    BorderSurface {
      width: parent ? parent.width : 0
      implicitHeight: summaryRow.implicitHeight + contentTopInset + contentBottomInset
      color: Util.alpha(root.stateColor, 0.08)
      borderSpec: Border.flat(Util.alpha(root.stateColor, 0.32), Style.normalBorderWidth)
      radius: Style.cornerRadius
      padding: Style.space(10)
      Row {
        id: summaryRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: parent.contentLeftInset
        spacing: Style.spacing.sm
        Text {
          text: Model.stateGlyph(root.snapshot.state)
          color: root.stateColor
          font.family: root.fontFamily
          font.pixelSize: Style.font.title
        }
        Column {
          width: parent.width - parent.spacing - parent.children[0].width
          Text {
            width: parent.width
            text: Model.stateLabel(root.snapshot.state)
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.title
            font.bold: true
          }
          Text {
            width: parent.width
            text: Model.statusMessage(root.snapshot)
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            wrapMode: Text.WordWrap
          }
        }
      }
    }
  }

  Component {
    id: actionRow
    Row {
      width: parent ? parent.width : 0
      spacing: Style.spacing.sm

      Button {
        visible: root.canStart
        width: visible ? (parent.width - parent.spacing) / 2 : 0
        text: "Start"
        iconText: "\uf04b"
        bordered: true
        enabled: !service.actionRunning
        foreground: root.foreground
        fontFamily: root.fontFamily
        onClicked: root.requestAction("start")
      }
      Button {
        visible: root.canStop
        width: visible ? (parent.width - parent.spacing * 2) / 3 : 0
        text: "Stop"
        iconText: "\uf04d"
        bordered: true
        enabled: !service.actionRunning
        foreground: root.urgent
        fontFamily: root.fontFamily
        onClicked: root.requestAction("stop")
      }
      Button {
        visible: root.canStop
        width: visible ? (parent.width - parent.spacing * 2) / 3 : 0
        text: "Restart"
        iconText: "\uf2f1"
        bordered: true
        enabled: !service.actionRunning
        foreground: root.foreground
        fontFamily: root.fontFamily
        onClicked: root.requestAction("restart")
      }
      Button {
        width: root.canStop ? (parent.width - parent.spacing * 2) / 3 : (parent.width - parent.spacing) / 2
        text: "Refresh"
        iconText: "\uf021"
        iconSpinning: service.refreshRunning
        bordered: true
        enabled: !service.actionRunning
        foreground: root.foreground
        fontFamily: root.fontFamily
        onClicked: service.refresh()
      }
    }
  }
}

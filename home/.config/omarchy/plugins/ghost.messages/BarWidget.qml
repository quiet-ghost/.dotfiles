import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

BarWidget {
  id: root
  moduleName: "ghost.messages"

  readonly property string scriptPath: Qt.resolvedUrl("history.sh").toString().replace("file://", "")
  readonly property var toplevels: Hyprland.toplevels ? Hyprland.toplevels.values : []
  readonly property var appStates: Model.appStates(toplevels)
  readonly property int urgentCount: {
    var count = 0
    for (var i = 0; i < appStates.length; i++) if (appStates[i].urgent) count++
    return count
  }
  readonly property var notifications: Model.chatNotifications(historyEntries)

  property bool opened: false
  property bool popoutSwitchClosing: false
  property var historyEntries: []
  property string historyError: ""
  property double now: Date.now()

  function open() {
    opened = true
    refresh()
  }
  function close() { opened = false }
  function toggle() { opened ? close() : open() }
  function closeForPopoutSwitch() {
    popoutSwitchClosing = true
    close()
    Qt.callLater(function() { root.popoutSwitchClosing = false })
  }
  function refresh() {
    now = Date.now()
    if (!historyProcess.running) historyProcess.running = true
  }
  function activateApp(app) {
    if (app.window && app.window.address) {
      Hyprland.dispatch("focuswindow address:" + app.window.address)
    } else {
      Util.execDetached("uwsm-app -- gtk-launch " + app.desktop)
    }
    close()
  }
  function activateNotification(notification) {
    for (var i = 0; i < appStates.length; i++) {
      if (appStates[i].id === notification.appId) {
        activateApp(appStates[i])
        return
      }
    }
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Process {
    id: historyProcess
    command: [root.scriptPath]
    stdout: StdioCollector { id: historyOutput; waitForEnd: true }
    stderr: StdioCollector { id: historyErrorOutput; waitForEnd: true }
    onExited: function(exitCode) {
      if (exitCode === 0) {
        root.historyEntries = Model.parseHistory(historyOutput.text)
        root.historyError = ""
      } else {
        root.historyError = String(historyErrorOutput.text || "") || "Could not read notification history"
      }
    }
  }

  Timer {
    interval: 30000
    running: root.opened
    repeat: true
    onTriggered: root.refresh()
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰍩"
    active: root.urgentCount > 0
    useActiveColor: true
    activeColor: Color.urgent
    tooltipText: root.urgentCount > 0
      ? String(root.urgentCount) + " messaging app(s) need attention"
      : "Messages"
    onPressed: function(code) {
      if (code === Qt.MiddleButton) root.refresh()
      else root.toggle()
    }
  }

  Rectangle {
    visible: root.urgentCount > 0
    width: Math.max(height, badgeText.implicitWidth + Style.space(4))
    height: Style.space(11)
    radius: height / 2
    color: Color.urgent
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.topMargin: Style.space(1)

    Text {
      id: badgeText
      anchors.centerIn: parent
      text: root.urgentCount
      textFormat: Text.PlainText
      color: Color.background
      font.family: root.bar.fontFamily
      font.pixelSize: Math.max(8, Style.font.caption - 2)
      font.bold: true
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    contentWidth: panel.fittedContentWidth(Style.space(430))
    contentHeight: panel.fittedContentHeight(content.implicitHeight, Style.space(620))

    Flickable {
      anchors.fill: parent
      contentWidth: width
      contentHeight: content.implicitHeight
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

      Column {
        id: content
        width: parent.width
        spacing: Style.space(12)

        PanelHero {
          width: parent.width
          title: "Messages"
          meta: root.urgentCount > 0
            ? String(root.urgentCount) + " app(s) need attention"
            : "Slack, Signal, and Discord"
          foreground: root.bar.foreground
          fontFamily: root.bar.fontFamily
          iconComponent: Component {
            Text {
              text: "󰍩"
              color: root.urgentCount > 0 ? Color.urgent : Color.accent
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.display
            }
          }
        }

        Column {
          width: parent.width
          spacing: Style.space(6)
          PanelSectionHeader { text: "APPS"; foreground: root.bar.foreground; fontFamily: root.bar.fontFamily }
          Repeater {
            model: root.appStates
            AppRow {
              required property var modelData
              width: parent.width
              app: modelData
            }
          }
        }

        PanelSeparator { foreground: root.bar.foreground }

        Column {
          width: parent.width
          spacing: Style.space(6)
          PanelSectionHeader { text: "RECENT"; foreground: root.bar.foreground; fontFamily: root.bar.fontFamily }

          Text {
            visible: root.notifications.length === 0
            width: parent.width
            text: "No recent Slack, Signal, or Discord notifications"
            textFormat: Text.PlainText
            color: Qt.darker(root.bar.foreground, 1.45)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.body
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
          }

          Repeater {
            model: root.notifications
            NotificationRow {
              required property var modelData
              width: parent.width
              notification: modelData
            }
          }
        }

        Text {
          visible: root.historyError !== ""
          width: parent.width
          text: root.historyError
          textFormat: Text.PlainText
          color: root.bar.urgent
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.bodySmall
          wrapMode: Text.WordWrap
        }
      }
    }
  }

  component AppRow: CursorSurface {
    id: appRow
    required property var app
    property bool hovered: false

    hasCursor: hovered
    foreground: root.bar.foreground
    implicitHeight: appLayout.implicitHeight + Style.spacing.rowPaddingX

    HoverHandler { onHoveredChanged: appRow.hovered = hovered }
    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: root.activateApp(appRow.app)
    }

    RowLayout {
      id: appLayout
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: Style.space(10)
      anchors.rightMargin: Style.space(10)
      spacing: Style.space(9)

      Text {
        text: appRow.app.icon
        color: appRow.app.urgent ? Color.urgent : root.bar.foreground
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.heading
      }
      ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.space(1)
        Text {
          Layout.fillWidth: true
          text: appRow.app.name
          textFormat: Text.PlainText
          color: root.bar.foreground
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.body
          font.bold: appRow.app.urgent
        }
        Text {
          Layout.fillWidth: true
          text: appRow.app.urgent ? "Needs attention" : (appRow.app.running ? "Running" : "Not running")
          textFormat: Text.PlainText
          color: appRow.app.urgent ? Color.urgent : Qt.darker(root.bar.foreground, 1.5)
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.bodySmall
        }
      }
      Text {
        text: "󰁔"
        color: Qt.darker(root.bar.foreground, 1.35)
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.body
      }
    }
  }

  component NotificationRow: CursorSurface {
    id: notificationRow
    required property var notification
    property bool hovered: false

    hasCursor: hovered
    foreground: root.bar.foreground
    implicitHeight: notificationLayout.implicitHeight + Style.spacing.rowPaddingX

    HoverHandler { onHoveredChanged: notificationRow.hovered = hovered }
    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: root.activateNotification(notificationRow.notification)
    }

    RowLayout {
      id: notificationLayout
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: Style.space(10)
      anchors.rightMargin: Style.space(10)
      spacing: Style.space(9)

      Text {
        text: notificationRow.notification.icon
        color: Qt.darker(root.bar.foreground, 1.25)
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.heading
        Layout.alignment: Qt.AlignTop
      }
      ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.space(2)
        RowLayout {
          Layout.fillWidth: true
          spacing: Style.space(8)
          Text {
            Layout.fillWidth: true
            text: notificationRow.notification.summary
            textFormat: Text.PlainText
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.body
            font.bold: true
            elide: Text.ElideRight
          }
          Text {
            text: Model.relativeTime(notificationRow.notification.timestamp, root.now)
            textFormat: Text.PlainText
            color: Qt.darker(root.bar.foreground, 1.55)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.bodySmall
          }
        }
        Text {
          visible: text !== ""
          Layout.fillWidth: true
          text: notificationRow.notification.body
          textFormat: Text.PlainText
          color: Qt.darker(root.bar.foreground, 1.4)
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.bodySmall
          wrapMode: Text.Wrap
          maximumLineCount: 2
          elide: Text.ElideRight
        }
        Text {
          Layout.fillWidth: true
          text: notificationRow.notification.appName
          textFormat: Text.PlainText
          color: Qt.darker(root.bar.foreground, 1.65)
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.caption
        }
      }
    }
  }
}

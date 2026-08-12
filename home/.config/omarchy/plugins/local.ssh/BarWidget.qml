import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "local.ssh"

  readonly property var sshService: bar?.shell?.serviceFor("local.ssh")
  readonly property var filteredHosts: {
    var result = []
    var query = String(searchText || "").trim().toLowerCase()
    var rows = sshService ? sshService.hosts : []
    for (var i = 0; i < rows.length; i++) {
      var row = rows[i]
      var haystack = (String(row.alias || "") + " " + String(row.hostname || "") + " " + String(row.user || "")).toLowerCase()
      if (query === "" || haystack.indexOf(query) !== -1) result.push(row)
    }
    return result
  }

  property bool opened: false
  property bool popoutSwitchClosing: false
  property string searchText: ""

  function open() { opened = true }
  function close() { opened = false; searchText = "" }
  function toggle() { opened ? close() : open() }
  function closeForPopoutSwitch() {
    popoutSwitchClosing = true
    close()
    Qt.callLater(function() { root.popoutSwitchClosing = false })
  }
  function connect(host) {
    if (sshService && sshService.connect(host)) close()
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.sshService && root.sshService.activeConnections.length > 0
      ? "󰣀 " + String(root.sshService.activeConnections.length)
      : "󰣀"
    active: root.sshService && root.sshService.activeConnections.length > 0
    tooltipText: root.sshService && root.sshService.activeConnections.length > 0
      ? String(root.sshService.activeConnections.length) + " active SSH connection(s)"
      : "SSH hosts"
    onPressed: function(code) {
      if (code === Qt.RightButton && root.sshService && root.sshService.previousHost !== "") root.connect(root.sshService.previousHost)
      else root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: search
    contentWidth: panel.fittedContentWidth(Style.space(400))
    contentHeight: panel.fittedContentHeight(content.implicitHeight, Style.space(600))

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
          title: "SSH"
          meta: root.sshService && root.sshService.activeConnections.length > 0
            ? String(root.sshService.activeConnections.length) + " active connection(s)"
            : "Connect to a configured host"
          foreground: root.bar.foreground
          fontFamily: root.bar.fontFamily
          iconComponent: Component {
            Text {
              text: "󰣀"
              color: root.sshService && root.sshService.activeConnections.length > 0 ? Color.accent : root.bar.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.display
            }
          }
        }

        TextField {
          id: search
          width: parent.width
          foreground: root.bar.foreground
          placeholderText: "Search hosts"
          text: root.searchText
          onTextChanged: root.searchText = text
          onAccepted: if (root.filteredHosts.length > 0) root.connect(root.filteredHosts[0].alias)
          Keys.onEscapePressed: root.close()
        }

        Column {
          visible: root.sshService && root.sshService.previousHost !== ""
          width: parent.width
          spacing: Style.space(6)
          PanelSectionHeader { text: "PREVIOUS"; foreground: root.bar.foreground; fontFamily: root.bar.fontFamily }
          HostRow {
            width: parent.width
            hostAlias: root.sshService ? root.sshService.previousHost : ""
            detail: "Connect again"
          }
        }

        Column {
          visible: root.sshService && root.sshService.activeConnections.length > 0
          width: parent.width
          spacing: Style.space(6)
          PanelSeparator { foreground: root.bar.foreground }
          PanelSectionHeader { text: "ACTIVE"; foreground: root.bar.foreground; fontFamily: root.bar.fontFamily }
          Repeater {
            model: root.sshService ? root.sshService.activeConnections : []
            HostRow {
              required property var modelData
              width: parent.width
              hostAlias: String(modelData.host || "")
              detail: "Connected to " + String(modelData.remote || "")
              activeConnection: true
            }
          }
        }

        Column {
          width: parent.width
          spacing: Style.space(6)
          PanelSeparator { foreground: root.bar.foreground }
          PanelSectionHeader { text: "HOSTS"; foreground: root.bar.foreground; fontFamily: root.bar.fontFamily }
          Text {
            visible: root.filteredHosts.length === 0
            width: parent.width
            text: root.searchText === "" ? "No hosts found in ~/.ssh/config" : "No matching hosts"
            color: Qt.darker(root.bar.foreground, 1.45)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.body
            horizontalAlignment: Text.AlignHCenter
          }
          Repeater {
            model: root.filteredHosts
            HostRow {
              required property var modelData
              width: parent.width
              hostAlias: String(modelData.alias || "")
              detail: {
                var user = String(modelData.user || "")
                var hostname = String(modelData.hostname || "")
                return user !== "" && hostname !== "" ? user + "@" + hostname : hostname
              }
            }
          }
        }

        Text {
          visible: root.sshService && root.sshService.error !== ""
          width: parent.width
          text: root.sshService ? root.sshService.error : ""
          color: root.bar.urgent
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.bodySmall
          wrapMode: Text.WordWrap
        }
      }
    }
  }

  component HostRow: CursorSurface {
    id: hostRow
    required property string hostAlias
    property string detail: ""
    property bool activeConnection: false

    foreground: root.bar.foreground
    implicitHeight: row.implicitHeight + Style.spacing.rowPaddingX

    RowLayout {
      id: row
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: Style.space(10)
      anchors.rightMargin: Style.space(10)
      spacing: Style.space(9)

      Text {
        text: hostRow.activeConnection ? "󰄬" : "󰌘"
        color: hostRow.activeConnection ? Color.accent : Qt.darker(root.bar.foreground, 1.35)
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.heading
      }
      ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.space(1)
        Text {
          Layout.fillWidth: true
          text: hostRow.hostAlias
          color: root.bar.foreground
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.body
          font.bold: hostRow.activeConnection
          elide: Text.ElideRight
        }
        Text {
          visible: text !== ""
          Layout.fillWidth: true
          text: hostRow.detail
          color: Qt.darker(root.bar.foreground, 1.5)
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.bodySmall
          elide: Text.ElideRight
        }
      }
      Text {
        text: "󰁔"
        color: Qt.darker(root.bar.foreground, 1.35)
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.body
      }
    }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.connect(hostRow.hostAlias)
    }
  }
}

import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "local.timer"

  readonly property var timerService: bar?.shell?.serviceFor("local.timer")
  property bool opened: false
  property bool popoutSwitchClosing: false
  property int customMinutes: 20

  function open() { opened = true }
  function close() { opened = false }
  function toggle() { opened = !opened }
  function closeForPopoutSwitch() {
    popoutSwitchClosing = true
    opened = false
    Qt.callLater(function() { root.popoutSwitchClosing = false })
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.timerService && root.timerService.active ? "󰔛 " + root.timerService.displayTime : "󰔛"
    active: root.timerService && root.timerService.active
    tooltipText: root.timerService && root.timerService.active
      ? root.timerService.label + " · right click to cancel"
      : "Timer and Pomodoro"
    onPressed: function(code) {
      if (code === Qt.RightButton && root.timerService && root.timerService.active) root.timerService.cancel()
      else root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: panelFocus
    contentWidth: panel.fittedContentWidth(Style.space(360))
    contentHeight: panel.fittedContentHeight(content.implicitHeight, Style.space(560))

    FocusScope {
      id: panelFocus
      anchors.fill: parent
      focus: true
      Keys.onEscapePressed: root.close()

      Column {
        id: content
        width: parent.width
        spacing: Style.space(14)

        PanelHero {
          width: parent.width
          title: root.timerService && root.timerService.active ? root.timerService.displayTime : "Timer"
          meta: root.timerService && root.timerService.active ? root.timerService.label : "Choose a preset or begin a focus cycle"
          foreground: root.bar.foreground
          fontFamily: root.bar.fontFamily
          iconComponent: Component {
            Text {
              text: "󰔛"
              color: root.timerService && root.timerService.active ? Color.accent : root.bar.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.display
            }
          }
        }

        PanelSectionHeader { text: "PRESETS"; foreground: root.bar.foreground; fontFamily: root.bar.fontFamily }

        Row {
          width: parent.width
          spacing: Style.space(5)
          Repeater {
            model: [5, 10, 15, 30, 60]
            Button {
              required property int modelData
              text: String(modelData) + "m"
              foreground: root.bar.foreground
              focusable: true
              onClicked: if (root.timerService) root.timerService.startMinutes(modelData, String(modelData) + " minute timer")
            }
          }
        }

        RowLayout {
          width: parent.width
          spacing: Style.space(8)
          NumberField {
            label: "Custom minutes"
            value: root.customMinutes
            from: 1
            to: 1440
            foreground: root.bar.foreground
            Layout.fillWidth: true
            onModified: function(value) { root.customMinutes = value }
          }
          Button {
            text: "Start"
            iconText: "󰐊"
            foreground: root.bar.foreground
            bordered: true
            focusable: true
            Layout.alignment: Qt.AlignBottom
            onClicked: if (root.timerService) root.timerService.startMinutes(root.customMinutes, String(root.customMinutes) + " minute timer")
          }
        }

        PanelSeparator { foreground: root.bar.foreground }
        PanelSectionHeader { text: "POMODORO"; foreground: root.bar.foreground; fontFamily: root.bar.fontFamily }

        RowLayout {
          width: parent.width
          spacing: Style.space(10)
          ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.space(2)
            Text {
              text: root.timerService ? root.timerService.nextPomodoroLabel : "Start focus 1"
              color: root.bar.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.subtitle
              font.bold: true
            }
            Text {
              text: "25m focus · 5m break · 15m after four"
              color: Qt.darker(root.bar.foreground, 1.45)
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.bodySmall
            }
          }
          Button {
            text: "Start"
            iconText: "󰐊"
            foreground: root.bar.foreground
            selected: true
            focusable: true
            enabled: !root.timerService || !root.timerService.active
            opacity: enabled ? 1 : 0.4
            onClicked: if (root.timerService) root.timerService.startPomodoro()
          }
        }

        Row {
          spacing: Style.space(6)
          Button {
            visible: root.timerService && root.timerService.active
            text: "Cancel"
            iconText: "󰜺"
            foreground: root.bar.foreground
            focusable: true
            onClicked: if (root.timerService) root.timerService.cancel()
          }
          Button {
            text: "Reset cycles"
            foreground: root.bar.foreground
            focusable: true
            onClicked: if (root.timerService) root.timerService.resetPomodoro()
          }
        }

        Text {
          visible: root.timerService && root.timerService.error !== ""
          width: parent.width
          text: root.timerService ? root.timerService.error : ""
          color: root.bar.urgent
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.bodySmall
          wrapMode: Text.WordWrap
        }
      }
    }
  }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "local.timer"

  readonly property var timerService: bar?.shell?.serviceFor("local.timer")
  property bool opened: false
  property bool popoutSwitchClosing: false
  property bool showSettings: false
  property int newPresetMinutes: 20
  property string newPomoName: "Study"
  property int newPomoFocus: 45
  property int newPomoShort: 10
  property int newPomoLong: 20
  property int newPomoEvery: 4

  function open() { opened = true }
  function close() { opened = false; showSettings = false }
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
    contentWidth: panel.fittedContentWidth(Style.space(420))
    contentHeight: panel.fittedContentHeight(content.implicitHeight, Style.space(520))

    FocusScope {
      id: panelFocus
      anchors.fill: parent
      focus: true
      Keys.onEscapePressed: root.close()

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

        RowLayout {
          width: parent.width
          PanelSectionHeader {
            text: "PRESETS"
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
            Layout.fillWidth: true
          }
          Button {
            text: root.showSettings ? "Done" : "Settings"
            foreground: root.bar.foreground
            focusable: true
            onClicked: root.showSettings = !root.showSettings
          }
        }

        Column {
          visible: !root.showSettings
          width: parent.width
          spacing: Style.space(14)

          Flow {
            width: parent.width
            spacing: Style.space(5)
            Repeater {
              model: root.timerService ? root.timerService.presets : [5, 10, 15, 25, 30, 45, 50, 60]
              Button {
                required property int modelData
                text: String(modelData) + "m"
                foreground: root.bar.foreground
                focusable: true
                onClicked: if (root.timerService) root.timerService.startMinutes(modelData, String(modelData) + " minute timer")
              }
            }
          }

          PanelSeparator { foreground: root.bar.foreground }
          PanelSectionHeader { text: "POMODORO"; foreground: root.bar.foreground; fontFamily: root.bar.fontFamily }

          Flow {
            width: parent.width
            spacing: Style.space(5)
            Repeater {
              model: root.timerService ? root.timerService.pomodoroPresets : []
              Button {
                required property var modelData
                text: modelData.name
                foreground: root.bar.foreground
                selected: root.timerService && root.timerService.currentPomodoro && root.timerService.currentPomodoro.name === modelData.name
                focusable: true
                enabled: !root.timerService || !root.timerService.active
                opacity: enabled ? 1 : 0.4
                onClicked: if (root.timerService) root.timerService.startPomodoro(modelData)
              }
            }
          }
        }

        Column {
          visible: root.showSettings
          width: parent.width
          spacing: Style.space(10)

          RowLayout {
            width: parent.width
            spacing: Style.space(8)
            NumberField {
              label: "Add minutes"
              value: root.newPresetMinutes
              from: 1
              to: 1440
              foreground: root.bar.foreground
              Layout.fillWidth: true
              onModified: function(value) { root.newPresetMinutes = value }
            }
            Button {
              text: "Add"
              foreground: root.bar.foreground
              bordered: true
              focusable: true
              Layout.alignment: Qt.AlignBottom
              onClicked: if (root.timerService) root.timerService.addPreset(root.newPresetMinutes)
            }
          }

          Flow {
            width: parent.width
            spacing: Style.space(5)
            Repeater {
              model: root.timerService ? root.timerService.presets : []
              Button {
                required property int modelData
                text: String(modelData) + "m"
                iconText: "󰅖"
                bordered: true
                foreground: root.bar.foreground
                focusable: true
                onClicked: if (root.timerService) root.timerService.removePreset(modelData)
              }
            }
          }

          PanelSeparator { foreground: root.bar.foreground }
          PanelSectionHeader { text: "POMODORO"; foreground: root.bar.foreground; fontFamily: root.bar.fontFamily }

          TextField {
            width: parent.width
            foreground: root.bar.foreground
            placeholderText: "Name"
            text: root.newPomoName
            onTextChanged: root.newPomoName = text
          }

          GridLayout {
            width: parent.width
            columns: 2
            columnSpacing: Style.space(10)
            rowSpacing: Style.space(8)
            NumberField {
              label: "Focus"
              value: root.newPomoFocus
              from: 1
              to: 1440
              fieldWidth: Style.space(160)
              foreground: root.bar.foreground
              Layout.fillWidth: true
              onModified: function(value) { root.newPomoFocus = value }
            }
            NumberField {
              label: "Break"
              value: root.newPomoShort
              from: 1
              to: 1440
              fieldWidth: Style.space(160)
              foreground: root.bar.foreground
              Layout.fillWidth: true
              onModified: function(value) { root.newPomoShort = value }
            }
            NumberField {
              label: "Long"
              value: root.newPomoLong
              from: 1
              to: 1440
              fieldWidth: Style.space(160)
              foreground: root.bar.foreground
              Layout.fillWidth: true
              onModified: function(value) { root.newPomoLong = value }
            }
            NumberField {
              label: "Long every"
              value: root.newPomoEvery
              from: 1
              to: 12
              fieldWidth: Style.space(160)
              foreground: root.bar.foreground
              Layout.fillWidth: true
              onModified: function(value) { root.newPomoEvery = value }
            }
          }

          Button {
            text: "Add pomodoro"
            foreground: root.bar.foreground
            bordered: true
            selected: true
            focusable: true
            onClicked: if (root.timerService) root.timerService.addPomodoro(root.newPomoName, root.newPomoFocus, root.newPomoShort, root.newPomoLong, root.newPomoEvery)
          }

          Flow {
            width: parent.width
            spacing: Style.space(5)
            Repeater {
              model: root.timerService ? root.timerService.pomodoroPresets : []
              Button {
                required property var modelData
                text: modelData.name
                iconText: "󰅖"
                bordered: true
                foreground: root.bar.foreground
                focusable: true
                onClicked: if (root.timerService) root.timerService.removePomodoro(modelData.name)
              }
            }
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
}

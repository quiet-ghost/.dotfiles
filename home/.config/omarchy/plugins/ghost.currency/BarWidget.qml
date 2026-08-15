import QtQuick
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "ghost.currency"

  readonly property var fx: bar?.shell?.serviceFor("ghost.currency")
  property bool opened: false
  property bool popoutSwitchClosing: false

  function open() { opened = true }
  function close() { opened = false }
  function toggle() { opened = !opened }
  function closeForPopoutSwitch() {
    popoutSwitchClosing = true
    opened = false
    Qt.callLater(function() { root.popoutSwitchClosing = false })
  }

  onOpenedChanged: if (opened && root.fx) {
    root.fx.refresh()
    Qt.callLater(function() {
      if (!amountField) return
      amountField.selectAll()
      amountField.forceActiveFocus()
    })
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.fx ? "󰎿 " + root.fx.displayText : "󰎿"
    tooltipText: root.fx && root.fx.rateText !== "" ? root.fx.rateText : "Currency converter"
    onPressed: function(code) {
      if (code === Qt.RightButton && root.fx) root.fx.swap()
      else if (code === Qt.MiddleButton && root.fx) root.fx.refresh()
      else root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: amountField
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(content.implicitHeight, Style.space(360))

    Column {
      id: content
      width: parent.width
      spacing: Style.space(12)

      PanelHero {
        width: parent.width
        title: root.fx ? root.fx.convertedText : "—"
        meta: root.fx && root.fx.rateText !== "" ? root.fx.rateText : "Fetching live rates"
        foreground: root.bar.foreground
        fontFamily: root.bar.fontFamily
        iconComponent: Component {
          Text {
            text: "󰎿"
            color: root.fx && root.fx.ready ? Color.accent : root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.display
          }
        }
      }

      TextField {
        id: amountField
        width: parent.width
        foreground: root.bar.foreground
        placeholderText: "Amount"
        text: root.fx ? root.fx.amountText : "1"
        inputMethodHints: Qt.ImhFormattedNumbersOnly
        onTextChanged: if (root.fx && root.fx.amountText !== text) root.fx.setAmount(text)
        onAccepted: root.close()
        Keys.onEscapePressed: root.close()
      }

      Column {
        width: parent.width
        spacing: Style.space(6)
        PanelSectionHeader { text: "FROM"; foreground: root.bar.foreground; fontFamily: root.bar.fontFamily }
        Flow {
          width: parent.width
          spacing: Style.space(5)
          Repeater {
            model: root.fx ? root.fx.currencyOptions : []
            Button {
              required property var modelData
              text: String(modelData.value || "")
              selected: root.fx && root.fx.fromCode === modelData.value
              foreground: root.bar.foreground
              focusable: true
              onClicked: if (root.fx) root.fx.setFrom(modelData.value)
            }
          }
        }
      }

      Button {
        width: parent.width
        text: "Swap"
        iconText: "⇄"
        bordered: true
        foreground: root.bar.foreground
        focusable: true
        onClicked: if (root.fx) root.fx.swap()
      }

      Column {
        width: parent.width
        spacing: Style.space(6)
        PanelSectionHeader { text: "TO"; foreground: root.bar.foreground; fontFamily: root.bar.fontFamily }
        Flow {
          width: parent.width
          spacing: Style.space(5)
          Repeater {
            model: root.fx ? root.fx.currencyOptions : []
            Button {
              required property var modelData
              text: String(modelData.value || "")
              selected: root.fx && root.fx.toCode === modelData.value
              foreground: root.bar.foreground
              focusable: true
              onClicked: if (root.fx) root.fx.setTo(modelData.value)
            }
          }
        }
      }

      RowLayout {
        width: parent.width
        spacing: Style.space(8)

        Text {
          Layout.fillWidth: true
          text: {
            if (!root.fx) return ""
            if (root.fx.refreshing) return "Updating rates"
            if (root.fx.rateDate !== "") return root.fx.rateDate + " · Frankfurter"
            return "Frankfurter live rates"
          }
          color: Qt.darker(root.bar.foreground, 1.45)
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.bodySmall
        }

        Button {
          text: "Refresh"
          foreground: root.bar.foreground
          focusable: true
          enabled: root.fx && !root.fx.refreshing
          onClicked: if (root.fx) root.fx.refresh()
        }
      }

      Text {
        visible: root.fx && root.fx.error !== ""
        width: parent.width
        text: root.fx ? root.fx.error : ""
        color: root.bar.urgent
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.bodySmall
        wrapMode: Text.WordWrap
      }
    }
  }
}

import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui
import "Model.js" as Model

BarWidget {
  id: root
  moduleName: "ghost.currency"

  readonly property color fg: bar ? bar.foreground : Color.foreground
  readonly property color urgent: bar && bar.urgent ? bar.urgent : Color.urgent
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property var hostedFx: bar?.shell?.serviceFor("ghost.currency")
  readonly property var fx: hostedFx || embeddedFx
  property bool opened: false
  property bool popoutSwitchClosing: false

  Service {
    id: embeddedFx
    visible: false
    manageIpc: false
    active: hostedFx === null || hostedFx === undefined
  }

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
    text: "\uf0d6"
    active: root.opened
    activeColor: Color.accent
    tooltipText: root.fx ? root.fx.displayText + "\nClick to convert" : "Currency converter"
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

      Rectangle {
        width: parent.width
        implicitHeight: resultContent.implicitHeight + Style.space(32)
        radius: Style.cornerRadius
        color: Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.08)
        border.color: Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.25)
        border.width: 1

        Column {
          id: resultContent
          x: Style.space(16)
          y: Style.space(16)
          width: parent.width - Style.space(32)
          spacing: Style.space(8)

          Text {
            width: parent.width
            text: {
              if (!root.fx) return "CONVERTED AMOUNT"
              var currency = Model.currency(root.fx.toCode)
              return (currency ? currency.name : root.fx.toCode) + " · " + root.fx.toCode
            }
            color: root.fg
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            font.bold: true
            wrapMode: Text.WordWrap
          }

          Text {
            width: parent.width
            text: root.fx && root.fx.ready ? Model.symbolFor(root.fx.toCode) + root.fx.convertedText : "—"
            color: Color.accent
            font.family: root.fontFamily
            font.pixelSize: Style.font.display * 1.5
            font.bold: true
            fontSizeMode: Text.HorizontalFit
            minimumPixelSize: Style.font.body
          }

          Text {
            width: parent.width
            text: root.fx && root.fx.rateText !== "" ? root.fx.rateText : "Fetching live rates"
            color: root.fg
            opacity: 0.7
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            wrapMode: Text.WordWrap
          }
        }
      }

      Column {
        width: parent.width
        spacing: Style.space(6)
        PanelSectionHeader {
          text: root.fx ? "FROM · " + root.fx.fromCode : "FROM"
          foreground: root.fg
          fontFamily: root.fontFamily
        }
        TextField {
          id: amountField
          width: parent.width
          foreground: root.fg
          placeholderText: "Amount"
          text: root.fx ? root.fx.amountText : "1"
          inputMethodHints: Qt.ImhFormattedNumbersOnly
          onTextChanged: if (root.fx && root.fx.amountText !== text) root.fx.setAmount(text)
          onAccepted: root.close()
          Keys.onEscapePressed: root.close()
        }
        Flow {
          width: parent.width
          spacing: Style.space(5)
          Repeater {
            model: root.fx ? root.fx.currencyOptions : []
            Button {
              required property var modelData
              text: String(modelData.value || "")
              selected: root.fx && root.fx.fromCode === modelData.value
              foreground: root.fg
              focusable: true
              onClicked: if (root.fx) root.fx.setFrom(modelData.value)
            }
          }
        }
      }

      Button {
        text: "Swap"
        iconText: "⇄"
        bordered: true
        foreground: root.fg
        focusable: true
        onClicked: if (root.fx) root.fx.swap()
      }

      Column {
        width: parent.width
        spacing: Style.space(6)
        PanelSectionHeader {
          text: root.fx ? "TO · " + root.fx.toCode : "TO"
          foreground: root.fg
          fontFamily: root.fontFamily
        }
        Flow {
          width: parent.width
          spacing: Style.space(5)
          Repeater {
            model: root.fx ? root.fx.currencyOptions : []
            Button {
              required property var modelData
              text: String(modelData.value || "")
              selected: root.fx && root.fx.toCode === modelData.value
              foreground: root.fg
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
          color: Qt.darker(root.fg, 1.45)
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
        }

        Button {
          text: "Refresh"
          foreground: root.fg
          focusable: true
          enabled: !!(root.fx && !root.fx.refreshing)
          onClicked: if (root.fx) root.fx.refresh()
        }
      }

      Text {
        visible: !!(root.fx && root.fx.error !== "")
        width: parent.width
        text: root.fx ? root.fx.error : ""
        color: root.urgent
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        wrapMode: Text.WordWrap
      }
    }
  }
}

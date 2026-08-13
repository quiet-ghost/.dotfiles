import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "ghost.govee"

  readonly property var lights: bar?.shell?.serviceFor("ghost.govee")
  property bool opened: false
  property bool popoutSwitchClosing: false
  property int pendingBrightness: -1
  property real hue: 196
  property real saturation: 1
  property string hexDraft: "#00c5ff"

  function open() { opened = true }
  function close() { opened = false }
  function toggle() { opened = !opened }
  function closeForPopoutSwitch() {
    popoutSwitchClosing = true
    opened = false
    Qt.callLater(function() { root.popoutSwitchClosing = false })
  }

  function clamp01(value) {
    return Math.max(0, Math.min(1, Number(value) || 0))
  }

  function hsvToHex(h, s, v) {
    var hue = ((Number(h) % 360) + 360) % 360 / 60
    var sat = root.clamp01(s)
    var val = root.clamp01(v)
    var chroma = val * sat
    var x = chroma * (1 - Math.abs((hue % 2) - 1))
    var m = val - chroma
    var r = 0, g = 0, b = 0
    if (hue < 1) { r = chroma; g = x }
    else if (hue < 2) { r = x; g = chroma }
    else if (hue < 3) { g = chroma; b = x }
    else if (hue < 4) { g = x; b = chroma }
    else if (hue < 5) { r = x; b = chroma }
    else { r = chroma; b = x }
    function byte(channel) {
      return Math.max(0, Math.min(255, Math.round((channel + m) * 255)))
    }
    return "#" + [byte(r), byte(g), byte(b)].map(function(n) {
      return n.toString(16).padStart(2, "0")
    }).join("")
  }

  function hexToHsv(hex) {
    var cleaned = String(hex || "").trim().replace(/^#/, "")
    if (!/^[0-9a-fA-F]{6}$/.test(cleaned)) return null
    var value = parseInt(cleaned, 16)
    var r = Math.floor(value / 65536) / 255
    var g = Math.floor((value % 65536) / 256) / 255
    var b = (value % 256) / 255
    var max = Math.max(r, g, b)
    var min = Math.min(r, g, b)
    var delta = max - min
    var nextHue = 0
    if (delta !== 0) {
      if (max === r) nextHue = ((g - b) / delta) % 6
      else if (max === g) nextHue = (b - r) / delta + 2
      else nextHue = (r - g) / delta + 4
      nextHue = ((nextHue * 60) + 360) % 360
    }
    return {
      hue: nextHue,
      saturation: max === 0 ? 0 : delta / max,
      hex: "#" + cleaned.toLowerCase()
    }
  }

  readonly property string wheelHex: root.hsvToHex(root.hue, root.saturation, 1)

  function applyHexToWheel(hex) {
    var parsed = root.hexToHsv(hex)
    if (!parsed) return false
    root.hue = parsed.hue
    root.saturation = parsed.saturation
    root.hexDraft = parsed.hex
    return true
  }

  function applyCurrentColor() {
    if (root.lights && root.lights.colorHex) root.applyHexToWheel(root.lights.colorHex)
  }

  function setWheelFromPoint(item, mouseX, mouseY) {
    var cx = item.width / 2
    var cy = item.height / 2
    var dx = mouseX - cx
    var dy = mouseY - cy
    var radius = Math.min(cx, cy)
    if (radius <= 0) return
    var distance = Math.sqrt(dx * dx + dy * dy)
    root.hue = ((Math.atan2(dy, dx) * 180 / Math.PI) + 360) % 360
    root.saturation = Math.max(0, Math.min(1, distance / radius))
    root.hexDraft = root.wheelHex
  }

  function pickColor(hex) {
    root.applyHexToWheel(hex)
    if (root.lights) root.lights.setColor(hex)
  }

  function addFavorite() {
    var hex = root.lights && root.lights.colorHex ? root.lights.colorHex : root.wheelHex
    if (root.lights) root.lights.saveFavorite(hex, hex)
  }

  onOpenedChanged: if (opened) root.applyCurrentColor()

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.lights && root.lights.powerOn ? "󰌵" : "󰌶"
    active: root.lights && root.lights.powerOn
    tooltipText: root.lights && root.lights.ready
      ? (root.lights.deviceName + (root.lights.powerOn ? " on" : " off"))
      : "Govee lights"
    onPressed: function(code) {
      if (code === Qt.RightButton && root.lights) root.lights.togglePower()
      else if (code === Qt.MiddleButton && root.lights) root.lights.refresh()
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
    contentHeight: panel.fittedContentHeight(content.implicitHeight, Style.space(720))

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
          spacing: Style.space(12)

          PanelHero {
            width: parent.width
            title: root.lights && root.lights.ready ? root.lights.deviceName : "Govee"
            meta: {
              if (!root.lights) return "Service not loaded"
              if (root.lights.busy) return "Talking to Govee"
              if (!root.lights.ready) return "Loading devices"
              if (root.lights.online === false) return "Device offline"
              return root.lights.powerOn ? "On · " + String(root.lights.brightness) + "%" : "Off"
            }
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
            iconComponent: Component {
              Text {
                text: root.lights && root.lights.powerOn ? "󰌵" : "󰌶"
                color: root.lights && root.lights.powerOn ? Color.accent : root.bar.foreground
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.display
              }
            }
          }

          Toggle {
            width: parent.width
            label: "Power"
            description: root.lights && root.lights.powerOn ? "Lamp is on" : "Lamp is off"
            checked: root.lights && root.lights.powerOn
            foreground: root.bar.foreground
            onClicked: if (root.lights) root.lights.togglePower()
          }

          Column {
            width: parent.width
            spacing: Style.space(6)
            PanelSectionHeader {
              text: "BRIGHTNESS"
              foreground: root.bar.foreground
              fontFamily: root.bar.fontFamily
            }
            PanelSlider {
              width: parent.width
              bar: root.bar
              minimum: 1
              maximum: 100
              step: 1
              integer: true
              value: root.pendingBrightness >= 0
                ? root.pendingBrightness
                : (root.lights ? root.lights.brightness : 1)
              onMoved: function(value) { root.pendingBrightness = value }
              onReleased: function(value) {
                root.pendingBrightness = -1
                if (root.lights) root.lights.setBrightness(value)
              }
            }
          }

          Column {
            visible: root.lights && root.lights.devices.length > 1
            width: parent.width
            spacing: Style.space(6)
            PanelSeparator { foreground: root.bar.foreground }
            PanelSectionHeader {
              text: "DEVICES"
              foreground: root.bar.foreground
              fontFamily: root.bar.fontFamily
            }
            Repeater {
              model: root.lights ? root.lights.devices : []
              Button {
                required property var modelData
                width: parent.width
                text: String(modelData.name || modelData.sku || "Device")
                selected: root.lights && root.lights.selectedKey === modelData.key
                foreground: root.bar.foreground
                focusable: true
                onClicked: if (root.lights) root.lights.selectDevice(modelData.key)
              }
            }
          }

          Column {
            width: parent.width
            spacing: Style.space(6)
            PanelSeparator { foreground: root.bar.foreground }
            PanelSectionHeader {
              text: "FAVORITES"
              foreground: root.bar.foreground
              fontFamily: root.bar.fontFamily
            }
            Flow {
              width: parent.width
              spacing: Style.space(6)
              Repeater {
                model: root.lights ? root.lights.savedColors : []
                Rectangle {
                  required property var modelData
                  width: Style.space(28)
                  height: width
                  radius: width / 2
                  color: String(modelData.hex || "#888888")
                  border.width: root.lights && root.lights.colorHex === modelData.hex ? 2 : 0
                  border.color: root.bar.foreground
                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.pickColor(modelData.hex)
                  }
                }
              }
              Button {
                text: "Add"
                bordered: true
                foreground: root.bar.foreground
                focusable: true
                onClicked: root.addFavorite()
              }
            }
          }

          Column {
            width: parent.width
            spacing: Style.space(6)
            PanelSeparator { foreground: root.bar.foreground }
            PanelSectionHeader {
              text: "WHITE"
              foreground: root.bar.foreground
              fontFamily: root.bar.fontFamily
            }
            Flow {
              width: parent.width
              spacing: Style.space(5)
              Repeater {
                model: root.lights ? root.lights.whites : [2700, 3000, 3500, 4000, 5000, 6500]
                Button {
                  required property var modelData
                  text: String(modelData) + "K"
                  selected: root.lights && root.lights.selected && root.lights.selected.colorTemperatureK === modelData
                  foreground: root.bar.foreground
                  focusable: true
                  onClicked: if (root.lights) root.lights.setKelvin(modelData)
                }
              }
            }
          }

          Column {
            width: parent.width
            spacing: Style.space(6)
            PanelSeparator { foreground: root.bar.foreground }
            PanelSectionHeader {
              text: "STANDARD COLORS"
              foreground: root.bar.foreground
              fontFamily: root.bar.fontFamily
            }
            Flow {
              width: parent.width
              spacing: Style.space(6)
              Repeater {
                model: root.lights ? root.lights.favoriteColors : []
                Rectangle {
                  required property var modelData
                  width: Style.space(28)
                  height: width
                  radius: width / 2
                  color: String(modelData.hex || "#888888")
                  border.width: root.lights && root.lights.colorHex === modelData.hex ? 2 : 0
                  border.color: root.bar.foreground
                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.pickColor(modelData.hex)
                  }
                }
              }
            }
          }

          Column {
            width: parent.width
            spacing: Style.space(8)
            PanelSeparator { foreground: root.bar.foreground }
            PanelSectionHeader {
              text: "CUSTOM"
              foreground: root.bar.foreground
              fontFamily: root.bar.fontFamily
            }

            Item {
              id: wheelHost
              width: parent.width
              height: Style.space(200)

              Canvas {
                id: wheelCanvas
                anchors.centerIn: parent
                width: Style.space(200)
                height: width
                onPaint: {
                  var ctx = getContext("2d")
                  var cx = width / 2
                  var cy = height / 2
                  var radius = Math.min(cx, cy)
                  ctx.clearRect(0, 0, width, height)
                  for (var angle = 0; angle < 360; angle++) {
                    var start = (angle - 1) * Math.PI / 180
                    var end = (angle + 1) * Math.PI / 180
                    ctx.beginPath()
                    ctx.moveTo(cx, cy)
                    ctx.arc(cx, cy, radius, start, end)
                    ctx.closePath()
                    ctx.fillStyle = root.hsvToHex(angle, 1, 1)
                    ctx.fill()
                  }
                  var fade = ctx.createRadialGradient(cx, cy, 0, cx, cy, radius)
                  fade.addColorStop(0, "#ffffffff")
                  fade.addColorStop(1, "#00ffffff")
                  ctx.beginPath()
                  ctx.arc(cx, cy, radius, 0, Math.PI * 2)
                  ctx.fillStyle = fade
                  ctx.fill()
                }
              }

              Rectangle {
                width: Style.space(16)
                height: width
                radius: width / 2
                color: root.wheelHex
                border.width: 2
                border.color: root.bar.foreground
                x: wheelCanvas.x + wheelCanvas.width / 2 + Math.cos(root.hue * Math.PI / 180) * root.saturation * (wheelCanvas.width / 2 - width / 2) - width / 2
                y: wheelCanvas.y + wheelCanvas.height / 2 + Math.sin(root.hue * Math.PI / 180) * root.saturation * (wheelCanvas.height / 2 - height / 2) - height / 2
              }

              MouseArea {
                anchors.fill: wheelCanvas
                cursorShape: Qt.PointingHandCursor
                onPressed: function(mouse) { root.setWheelFromPoint(wheelCanvas, mouse.x, mouse.y) }
                onPositionChanged: function(mouse) {
                  if (pressed) root.setWheelFromPoint(wheelCanvas, mouse.x, mouse.y)
                }
                onReleased: if (root.lights) root.lights.setColor(root.wheelHex)
              }
            }

            RowLayout {
              width: parent.width
              spacing: Style.space(8)
              Rectangle {
                width: Style.space(28)
                height: width
                radius: Style.cornerRadius
                color: root.wheelHex
                border.width: 1
                border.color: Qt.darker(root.bar.foreground, 1.6)
              }
              TextField {
                Layout.fillWidth: true
                foreground: root.bar.foreground
                text: root.hexDraft
                placeholderText: "#00c5ff"
                onTextChanged: root.hexDraft = text
                onAccepted: {
                  if (root.applyHexToWheel(root.hexDraft) && root.lights)
                    root.lights.setColor(root.wheelHex)
                }
              }
              Button {
                text: "Set"
                foreground: root.bar.foreground
                focusable: true
                onClicked: {
                  if (root.applyHexToWheel(root.hexDraft) && root.lights)
                    root.lights.setColor(root.wheelHex)
                }
              }
            }
          }

          Text {
            visible: root.lights && root.lights.warning !== ""
            width: parent.width
            text: root.lights ? root.lights.warning : ""
            color: Qt.darker(root.bar.foreground, 1.3)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.bodySmall
            wrapMode: Text.WordWrap
          }

          Text {
            visible: root.lights && root.lights.error !== ""
            width: parent.width
            text: root.lights ? root.lights.error : ""
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

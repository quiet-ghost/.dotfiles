import Quickshell
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell.Services.SystemTray
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "TrayModel.js" as TrayModel

// Omarchy's tray (omarchy.tray), plus status icons you can arrange by hand.
// Bar widgets live in the host's own tray section (bar.layout.tray), which the
// bar draws into sectionHost and drags in and out itself. Status icons have no
// layout entry, so this widget drags those: within the drawer, onto the pinned
// strip, or off the bar to hide them. See README.md.
BarWidget {
  id: root
  moduleName: "ghost.tray"

  property bool expanded: false
  // A panel's focus grab swallows hover, so the chevron must also open the
  // drawer by click. Cleared when the pointer leaves the drawer.
  property bool clickExpanded: false
  property bool managePopupOpen: false
  property bool trayMenuOpen: false
  property var activeTrayItem: null
  property var activeTrayAnchor: null
  readonly property color foreground: bar ? bar.foreground : Commons.Color.foreground
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property var pinnedIds: TrayModel.stringList(settings.pinned)
  readonly property var hiddenIds: TrayModel.stringList(settings.hidden)
  readonly property var orderIds: TrayModel.stringList(settings.order)
  // Master switch: off takes every status icon off the bar. They stay listed in
  // the manage panel for when it comes back on.
  readonly property bool showTrayIcons: settings.showTrayIcons !== false
  readonly property var pinnedItems: bucket("pinned")
  readonly property var drawerItems: bucket("drawer")
  readonly property var allItems: bucket("all")
  readonly property int drawerCount: drawerItems.length
  readonly property int trayItemExtent: Style.bar.iconSlot
  readonly property int trayItemGap: 0
  readonly property int trayJoinGap: 0
  // Bar widgets dragged into the tray section sit in the drawer after the
  // app icons. The bar draws them into sectionHost, and outlines it while a
  // widget is dragged, as it does the center box.
  property Item sectionHost: null
  // The part of the tray section the drawer shows, in the tray ({ x, y,
  // width, height }), or null while it shows none of it. It moves with the
  // drawer's contents as they slide in and out, and is cut to the drawer as
  // they are, so the bar's outline of it never reaches past the tray.
  readonly property var sectionShown: trayContent.item ? trayContent.item.sectionShown : null
  readonly property int sectionCount: bar && bar.layoutConfig && Array.isArray(bar.layoutConfig.tray) ? bar.layoutConfig.tray.length : 0
  readonly property real sectionExtent: sectionHost ? (vertical ? sectionHost.implicitHeight : sectionHost.implicitWidth) : 0
  readonly property bool hasDrawer: allItems.length > 0 || sectionCount > 0 || barDragging
  readonly property int drawerExtent: drawerCount * trayItemExtent + Math.max(0, drawerCount - 1) * trayItemGap + sectionExtent
  // A widget being dragged along the bar opens the drawer, to show where it
  // can go, and so does any panel open from the tray or the tray section.
  readonly property bool barDragging: !!bar && bar.traySectionDragActive === true
  readonly property bool holdOpen: trayMenuOpen || managePopupOpen || barDragging || iconDragActive || (!!bar && bar.traySectionPopoutOpen === true)
  // The mark under the bar sits under the icon whose menu is open.
  readonly property Item openPanelIndicatorItem: trayMenuOpen ? activeTrayAnchor : null
  // Match Waybar's group/tray-expander drawer transition-duration.
  readonly property int animationDuration: 600
  property real revealProgress: expanded || clickExpanded || holdOpen ? 1 : 0
  readonly property real revealExtent: drawerExtent * revealProgress
  // The pinned icons sit against the tray's fixed edge with the chevron past
  // them. Opening, the drawer grows the tray between the two and pushes the
  // chevron out of the way, while the pointer that opened it stays over the
  // drawer. A centered tray keeps the end-fixed arrangement.
  readonly property bool fixedAtStart: fixedEdge === "start"
  // The edge the tray section's widgets grow from: the one the pinned icons
  // keep to, beside which the section opens.
  readonly property string sectionEdge: fixedAtStart ? "start" : "end"

  function closeExteriorPopout() {
    var popout = root.bar ? root.bar.activePopout : null
    if (popout && popout !== root && typeof popout.close === "function") popout.close()
  }

  function chevronPressed(button) {
    if (button === Qt.RightButton) {
      root.managePopupOpen = !root.managePopupOpen
    } else if (button === Qt.LeftButton) {
      root.closeExteriorPopout()
      root.clickExpanded = true
    }
  }

  // ---------------------------------------------------------------------------
  // Dragging status icons. The bar's slot lays a MouseArea over its whole widget
  // and turns any press into a drag of the widget, so nothing inside the tray
  // can ever see one. This overlay sits above that MouseArea, in the slot, and
  // takes only presses on icons; everything else falls through, so the chevron
  // still moves the tray and the section's widgets still drag themselves.
  // ---------------------------------------------------------------------------

  // The slot showing this widget. It changes when the tray moves between
  // sections, so it is read from the host rather than found once.
  readonly property Item hostSlot: {
    var p = parent
    for (var i = 0; i < 8 && p; i++) {
      if ("owner" in p && "pool" in p) return p.owner
      p = p.parent
    }
    return null
  }

  property var iconDelegates: []
  property Item iconDragItem: null
  property bool iconDragActive: false
  property var iconDrop: null
  property real iconDragSceneX: 0
  property real iconDragSceneY: 0

  readonly property bool canPersist: !!root.bar && !!root.bar.shell && typeof root.bar.shell.updateEntryInline === "function"

  function registerIconDelegate(item) {
    if (iconDelegates.indexOf(item) === -1) iconDelegates = iconDelegates.concat([item])
  }

  function unregisterIconDelegate(item) {
    iconDelegates = iconDelegates.filter(function(other) { return other !== item })
    if (iconDragItem === item) cancelIconDrag()
  }

  function cancelIconDrag() {
    iconDragActive = false
    iconDragItem = null
    iconDrop = null
  }

  function contains(item, x, y) {
    return x >= 0 && y >= 0 && x <= item.width && y <= item.height
  }

  // The icon at a point in the overlay. A closed drawer's icons are still laid
  // out, under the chevron, so they count only where its clip shows them.
  function iconAt(overlay, x, y) {
    var clip = trayContent.item ? trayContent.item.iconClip : null
    for (var i = 0; i < iconDelegates.length; i++) {
      var icon = iconDelegates[i]
      if (!icon || !icon.visible) continue
      var inIcon = overlay.mapToItem(icon, x, y)
      if (!contains(icon, inIcon.x, inIcon.y)) continue
      if (icon.zone === "pinned") return icon
      if (!clip) continue
      var inClip = overlay.mapToItem(clip, x, y)
      if (contains(clip, inClip.x, inClip.y)) return icon
    }
    return null
  }

  function span(item) {
    var origin = item.mapToItem(null, 0, 0)
    return vertical ? { start: origin.y, length: item.height } : { start: origin.x, length: item.width }
  }

  function updateIconDrop() {
    var content = trayContent.item
    if (!content || !iconDragItem) return
    var origin = root.mapToItem(null, 0, 0)
    var across = vertical ? iconDragSceneX : iconDragSceneY
    var acrossStart = vertical ? origin.x : origin.y
    var rows = []
    for (var i = 0; i < iconDelegates.length; i++) {
      var icon = iconDelegates[i]
      if (!icon || !icon.visible) continue
      var iconSpan = span(icon)
      rows.push({ id: icon.itemId, zone: icon.zone, start: iconSpan.start, length: iconSpan.length })
    }
    iconDrop = TrayModel.iconDrop({
      axis: vertical ? iconDragSceneY : iconDragSceneX,
      outside: Math.max(0, acrossStart - across, across - (acrossStart + barSize)),
      removeDistance: Style.spaceReal(48),
      tray: span(root),
      pinned: span(content.pinnedStrip),
      drawer: span(content.iconClip),
      rows: rows,
      draggedId: iconDragItem.itemId
    })
  }

  function applyIconDrop(id, drop) {
    var next = TrayModel.moveIcon(
      { pinned: pinnedIds, hidden: hiddenIds, order: orderIds },
      id,
      drop,
      drawerItems.map(function(item) { return String(item.id || "") })
    )
    persistState(next)
  }

  Item {
    id: iconDragOverlay
    parent: root.hostSlot || root
    visible: root.visible && !!root.hostSlot
    anchors.fill: parent
    z: 60

    MouseArea {
      id: iconDragMouse

      property Item pressedIcon: null
      property real pressSceneX: 0
      property real pressSceneY: 0
      property bool suppressClick: false

      anchors.fill: parent
      acceptedButtons: Qt.LeftButton

      onPressed: function(mouse) {
        suppressClick = false
        pressedIcon = root.iconAt(iconDragMouse, mouse.x, mouse.y)
        if (!pressedIcon) {
          mouse.accepted = false
          return
        }
        var scene = iconDragMouse.mapToItem(null, mouse.x, mouse.y)
        pressSceneX = scene.x
        pressSceneY = scene.y
      }

      onPositionChanged: function(mouse) {
        if (!pressedIcon || !root.canPersist) return
        var scene = iconDragMouse.mapToItem(null, mouse.x, mouse.y)
        if (!root.iconDragActive) {
          if (Math.abs(scene.x - pressSceneX) + Math.abs(scene.y - pressSceneY) < Style.space(4)) return
          root.iconDragItem = pressedIcon
          root.iconDragActive = true
          if (root.bar) root.bar.hideTooltip(pressedIcon)
        }
        root.iconDragSceneX = scene.x
        root.iconDragSceneY = scene.y
        root.updateIconDrop()
      }

      onReleased: function(mouse) {
        var wasDragging = root.iconDragActive
        var id = root.iconDragItem ? root.iconDragItem.itemId : ""
        var drop = root.iconDrop
        root.cancelIconDrag()
        if (!wasDragging) return
        suppressClick = true
        // After the release: the write rebuilds the icon rows under this handler.
        if (id && drop) Qt.callLater(function() { root.applyIconDrop(id, drop) })
      }

      onCanceled: {
        pressedIcon = null
        root.cancelIconDrag()
      }

      onClicked: function(mouse) {
        var icon = pressedIcon
        pressedIcon = null
        if (suppressClick || !icon) return
        var point = iconDragMouse.mapToItem(icon, mouse.x, mouse.y)
        icon.primaryClick(point)
      }
    }
  }

  // What the drag looks like: the icon under the pointer, and a line where it
  // will land. On the bar window, since the drawer clips its own contents.
  Item {
    id: iconDragVisuals
    parent: root.QsWindow && root.QsWindow.window ? root.QsWindow.window.contentItem : root
    visible: root.iconDragActive
    anchors.fill: parent
    z: 900

    TrayIcon {
      width: Style.bar.iconSize
      height: Style.bar.iconSize
      x: root.iconDragSceneX - width / 2
      y: root.iconDragSceneY - height / 2
      opacity: root.iconDrop && root.iconDrop.zone === "hidden" ? 0.35 : 1
      icon: root.iconDragItem && root.iconDragItem.modelData ? root.iconDragItem.modelData.icon : ""
    }

    Rectangle {
      readonly property bool shown: !!root.iconDrop && root.iconDrop.zone !== "hidden"
      readonly property real origin: {
        if (!shown) return 0
        var corner = root.mapToItem(null, 0, 0)
        return root.vertical ? corner.x : corner.y
      }

      visible: shown
      color: Commons.Color.accent
      radius: Math.max(1, Style.space(1))
      width: root.vertical ? root.barSize : Math.max(2, Style.space(2))
      height: root.vertical ? Math.max(2, Style.space(2)) : root.barSize
      x: root.vertical ? origin : (shown ? root.iconDrop.markerAt - width / 2 : 0)
      y: root.vertical ? (shown ? root.iconDrop.markerAt - height / 2 : 0) : origin
    }
  }

  // ---------------------------------------------------------------------------
  // Submenu drill-down state. QsMenuEntry.display() renders a *platform* menu,
  // which Quickshell refuses unless the shell root sets `//@ pragma
  // UseQApplication` - omarchy's shell.qml does not, so every submenu click was
  // a silent no-op and apps whose whole UI is submenus were unusable.
  // QsMenuEntry inherits QsMenuHandle, so a child entry can feed a nested
  // QsMenuOpener and render inside this popup instead of going through the
  // platform. Each level keeps its own live opener: a child entry is owned by
  // its parent opener's model, so collapsing the stack to a single opener
  // would destroy the very entry being displayed.
  // ---------------------------------------------------------------------------
  property var submenuStack: []
  readonly property int submenuDepth: submenuStack.length
  readonly property string currentTitle: submenuDepth > 0 ? submenuStack[submenuDepth - 1].title : ""
  readonly property var currentChildren: submenuDepth > 0
    ? submenuStack[submenuDepth - 1].opener.children
    : trayMenuOpener.children

  // Changing level rebuilds the row delegates synchronously, so the next
  // row lands under a cursor that hasn't moved. Ignore row clicks for a beat
  // after each level change; a deliberate follow-up click is slower.
  property bool menuLevelSettling: false

  Component {
    id: submenuOpenerComponent
    QsMenuOpener {}
  }

  Timer {
    id: menuLevelSettleTimer
    interval: 250
    onTriggered: root.menuLevelSettling = false
  }

  function settleMenuLevel() {
    menuLevelSettling = true
    menuLevelSettleTimer.restart()
  }

  function resetTrayMenu() {
    menuLevelSettling = false
    menuLevelSettleTimer.stop()
    // Flickable keeps its offset across a model swap whenever the new content
    // is still tall enough to hold it, so a menu dismissed while scrolled
    // would otherwise reopen part-way down with its first entries off screen.
    trayMenuFlick.contentY = 0
    // Clear the reactive stack before tearing anything down, then destroy
    // deepest first: an inner opener's menu entry is owned by its parent's
    // children model.
    var openers = submenuStack
    submenuStack = []
    for (var i = openers.length - 1; i >= 0; i--) openers[i].opener.destroy()
  }

  function enterSubmenu(entry, title) {
    var opener = submenuOpenerComponent.createObject(root, { menu: entry })
    if (!opener) return
    var stack = submenuStack.slice()
    stack.push({ opener: opener, title: title })
    submenuStack = stack
    settleMenuLevel()
  }

  function leaveSubmenu() {
    if (submenuStack.length === 0) return
    var stack = submenuStack.slice()
    var top = stack.pop()
    submenuStack = stack
    top.opener.destroy()
    settleMenuLevel()
  }

  function close() {
    managePopupOpen = false
    trayMenuOpen = false
  }

  function openTrayMenu(item, anchorItem, mouse) {
    if (!item || !item.menu) {
      var point = anchorItem.QsWindow.contentItem.mapFromItem(anchorItem, mouse.x, mouse.y)
      item.display(anchorItem.QsWindow.window, point.x, point.y)
      return
    }

    // Reset before switching items: trayMenuOpener.menu binds to
    // activeTrayItem.menu, so assigning a new item invalidates the old root's
    // children immediately.
    resetTrayMenu()
    activeTrayItem = item
    activeTrayAnchor = anchorItem
    // Kill any pending tooltip for the icon under the cursor: with the menu
    // open, a "Dropbox" bubble popping up over it is pure noise.
    if (root.bar) root.bar.hideTooltip(anchorItem)
    trayMenuOpen = true
  }

  function trayIconSource(icon) {
    // Quickshell already resolves the tray icon into a ready-to-use image://
    // URL, including a "?path=" fallback search dir for apps that ship their
    // tray icon outside a standard theme.
    return String(icon || "")
  }

  // Symbolic icons ship a fixed fill the host is meant to recolor; detect by
  // the freedesktop "-symbolic" name suffix so they can be tinted.
  function iconIsSymbolic(icon) {
    var name = String(icon || "").split("?")[0]
    return name.slice(-9) === "-symbolic"
  }


  // The bar's shared tooltip label uses Text.AutoText. Wrap application metadata
  // in known-safe rich text so an app cannot inject markup.
  function escapedTooltipText(value) {
    var text = String(value || "")
    if (!text) return ""
    return "<span>" + text
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/\r\n|\r|\n/g, "<br>") + "</span>"
  }

  function trayTooltip(item) {
    return escapedTooltipText(item.tooltipTitle || item.title || item.id || "")
  }

  function classifyItem(item) {
    var iid = String(item.id || "")
    if (hiddenIds.indexOf(iid) !== -1) return "hidden"
    if (pinnedIds.indexOf(iid) !== -1) return "pinned"
    return "drawer"
  }

  function ownedByOmarchy(item) {
    var layout = root.bar && root.bar.layoutConfig ? root.bar.layoutConfig : null
    return TrayModel.ownedByOmarchy(item, layout)
  }

  function bucket(category) {
    var values = SystemTray.items.values
    var result = []
    for (var i = 0; i < values.length; i++) {
      var item = values[i]
      if (item.status === Status.Passive) continue
      if (ownedByOmarchy(item)) continue
      if (category === "all") {
        result.push(item)
        continue
      }
      if (!showTrayIcons) continue
      if (classifyItem(item) === category) result.push(item)
    }
    return TrayModel.sortByOrder(result, category === "pinned" ? pinnedIds : orderIds)
  }

  // updateEntryInline replaces the whole layout entry, so every setting has to
  // ride along on every write or a toggle would silently drop the others.
  function persistState(overrides) {
    if (!canPersist) return
    var id = root.moduleName || "ghost.tray"
    var payload = { id: id }
    var current = root.settings || {}
    for (var key in current) {
      if (key !== "id") payload[key] = current[key]
    }
    for (var name in overrides) payload[name] = overrides[name]
    root.bar.shell.updateEntryInline(id, payload)
  }

  function togglePin(iid) {
    var pinned = pinnedIds.slice()
    var hidden = hiddenIds.filter(function(other) { return other !== iid })
    var at = pinned.indexOf(iid)
    if (at !== -1) pinned.splice(at, 1)
    else pinned.push(iid)
    persistState({ pinned: pinned, hidden: hidden })
  }

  function toggleHide(iid) {
    var hidden = hiddenIds.slice()
    var pinned = pinnedIds.filter(function(other) { return other !== iid })
    var at = hidden.indexOf(iid)
    if (at !== -1) hidden.splice(at, 1)
    else hidden.push(iid)
    persistState({ pinned: pinned, hidden: hidden })
  }

  visible: pinnedItems.length > 0 || hasDrawer
  clip: false
  implicitWidth: root.vertical ? root.barSize : trayContent.implicitWidth
  implicitHeight: root.vertical ? trayContent.implicitHeight : root.barSize

  Behavior on revealProgress {
    NumberAnimation { duration: Style.duration(root.animationDuration); easing.type: Easing.OutCubic }
  }

  // The section from `start`, `length` long along the bar, as far as the
  // drawer's clip from `clipStart`, `clipLength` long, shows it
  // (TrayModel.shownSpan).
  function shownSection(clipStart, clipLength, start, length) {
    var span = TrayModel.shownSpan(clipStart, clipLength, start, length)
    if (!span) return null
    return vertical
      ? { x: 0, y: span.start, width: barSize, height: span.length }
      : { x: span.start, y: 0, width: span.length, height: barSize }
  }

  Loader {
    id: trayContent
    anchors.fill: parent
    sourceComponent: root.vertical ? verticalTray : horizontalTray
  }

  Component {
    id: horizontalTray

    Item {
      id: horizontalTrayRoot

      readonly property int chevronWidth: root.hasDrawer ? expandIcon.implicitWidth : 0
      readonly property Item pinnedStrip: pinnedRow
      readonly property Item iconClip: trayClip
      readonly property var sectionShown: root.shownSection(drawerArea.x + trayClip.x, trayClip.width, drawerArea.x + trayClip.x + drawerContent.x + section.x, section.width)

      implicitWidth: pinnedRow.implicitWidth + chevronWidth + root.revealExtent
      implicitHeight: root.barSize

      Item {
        id: drawerArea
        x: root.fixedAtStart ? pinnedRow.implicitWidth : 0
        width: horizontalTrayRoot.chevronWidth + root.revealExtent
        height: root.barSize
        visible: root.hasDrawer

        HoverHandler {
          onHoveredChanged: {
            root.expanded = hovered
            if (!hovered) root.clickExpanded = false
          }
        }

        BarIconButton {
          id: expandIcon
          bar: root.bar
          width: implicitWidth
          height: implicitHeight
          x: root.fixedAtStart ? root.revealExtent : 0
          text: root.fixedAtStart ? "\uf054" : "\uf053"
          onPressed: function(button) { root.chevronPressed(button) }
        }

        // The icons and the tray section travel out with the chevron from
        // beside the pinned icons, the section nearest them.
        Item {
          id: trayClip
          x: root.fixedAtStart ? 0 : expandIcon.width
          anchors.verticalCenter: parent.verticalCenter
          width: root.revealExtent
          height: root.barSize
          clip: true

          Item {
            id: drawerContent
            x: root.fixedAtStart ? root.revealExtent - root.drawerExtent : 0
            width: root.drawerExtent
            height: root.barSize

            Row {
              id: trayIcons
              x: root.fixedAtStart ? root.sectionExtent : 0
              anchors.verticalCenter: parent.verticalCenter
              spacing: root.trayItemGap
              layer.enabled: true

              Repeater {
                model: root.drawerItems
                TrayItem { zone: "drawer" }
              }
            }

            // Placed by hand: a Row leaves a child with no width where it
            // was, and an empty section has none.
            SectionArea {
              id: section
              x: root.fixedAtStart ? 0 : trayIcons.width
              anchors.verticalCenter: parent.verticalCenter
            }
          }
        }
      }

      Row {
        id: pinnedRow
        x: root.fixedAtStart ? 0 : drawerArea.width
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.trayItemGap
        leftPadding: !root.fixedAtStart && root.pinnedItems.length > 0 && root.allItems.length > 0 ? root.trayJoinGap : 0
        rightPadding: root.fixedAtStart && root.pinnedItems.length > 0 && root.allItems.length > 0 ? root.trayJoinGap : 0
        // An empty strip has no size, so a drag gets one icon's room to land in.
        Item {
          visible: root.iconDragActive && root.pinnedItems.length === 0
          width: root.trayItemExtent
          height: root.trayItemExtent
        }
        Repeater {
          model: root.pinnedItems
          TrayItem { zone: "pinned" }
        }
      }
    }
  }

  Component {
    id: verticalTray

    Item {
      id: verticalTrayRoot

      readonly property int chevronHeight: root.hasDrawer ? expandIcon.implicitHeight : 0
      readonly property Item pinnedStrip: pinnedCol
      readonly property Item iconClip: trayClip
      readonly property var sectionShown: root.shownSection(drawerArea.y + trayClip.y, trayClip.height, drawerArea.y + trayClip.y + drawerContent.y + section.y, section.height)

      implicitWidth: root.barSize
      implicitHeight: pinnedCol.implicitHeight + chevronHeight + root.revealExtent

      Item {
        id: drawerArea
        y: root.fixedAtStart ? pinnedCol.implicitHeight : 0
        width: root.barSize
        height: verticalTrayRoot.chevronHeight + root.revealExtent
        visible: root.hasDrawer

        HoverHandler {
          onHoveredChanged: {
            root.expanded = hovered
            if (!hovered) root.clickExpanded = false
          }
        }

        BarIconButton {
          id: expandIcon
          bar: root.bar
          width: implicitWidth
          height: implicitHeight
          y: root.fixedAtStart ? root.revealExtent : 0
          text: root.fixedAtStart ? "\uf054" : "\uf053"
          textRotation: 90
          onPressed: function(button) { root.chevronPressed(button) }
        }

        // The icons and the tray section travel out with the chevron from
        // beside the pinned icons, the section nearest them.
        Item {
          id: trayClip
          y: root.fixedAtStart ? 0 : expandIcon.height
          anchors.horizontalCenter: parent.horizontalCenter
          width: root.barSize
          height: root.revealExtent
          clip: true

          Item {
            id: drawerContent
            y: root.fixedAtStart ? root.revealExtent - root.drawerExtent : 0
            width: root.barSize
            height: root.drawerExtent

            Column {
              id: trayIcons
              y: root.fixedAtStart ? root.sectionExtent : 0
              anchors.horizontalCenter: parent.horizontalCenter
              spacing: root.trayItemGap
              layer.enabled: true

              Repeater {
                model: root.drawerItems
                TrayItem { zone: "drawer" }
              }
            }

            // Placed by hand: a Column leaves a child with no height where it
            // was, and an empty section has none.
            SectionArea {
              id: section
              y: root.fixedAtStart ? 0 : trayIcons.height
              anchors.horizontalCenter: parent.horizontalCenter
            }
          }
        }
      }

      Column {
        id: pinnedCol
        y: root.fixedAtStart ? 0 : drawerArea.height
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: root.trayItemGap
        topPadding: !root.fixedAtStart && root.pinnedItems.length > 0 && root.allItems.length > 0 ? root.trayJoinGap : 0
        bottomPadding: root.fixedAtStart && root.pinnedItems.length > 0 && root.allItems.length > 0 ? root.trayJoinGap : 0
        // An empty strip has no size, so a drag gets one icon's room to land in.
        Item {
          visible: root.iconDragActive && root.pinnedItems.length === 0
          width: root.trayItemExtent
          height: root.trayItemExtent
        }
        Repeater {
          model: root.pinnedItems
          TrayItem { zone: "pinned" }
        }
      }
    }
  }

  // The popup anchors to a frozen snapshot of the tray's rect rather than
  // the live widget: toggling icons resizes the drawer, which moves the
  // tray, and a live anchor would drag the open modal around with it. The
  // snapshot is parented to the bar window so slot reflow can't move it.
  Item {
    id: popupAnchorProxy
    parent: root.QsWindow && root.QsWindow.window ? root.QsWindow.window.contentItem : root
    visible: false
  }

  function snapshotPopupAnchor() {
    var win = root.QsWindow ? root.QsWindow.window : null
    if (!win || !win.contentItem) return
    var p = root.mapToItem(win.contentItem, 0, 0)
    popupAnchorProxy.x = p.x
    popupAnchorProxy.y = p.y
    popupAnchorProxy.width = root.width
    popupAnchorProxy.height = root.height
  }

  onManagePopupOpenChanged: if (managePopupOpen) snapshotPopupAnchor()

  // KeyboardPanel rather than PopupCard: an xdg-popup can never take layer
  // keyboard focus, so Escape could not reach it. This is the same base the
  // bluetooth/network modals use — Escape closes, click-away dismisses.
  KeyboardPanel {
    id: managePopup
    anchorItem: popupAnchorProxy
    owner: root
    bar: root.bar
    open: root.managePopupOpen
    contentWidth: managePopup.fittedContentWidth(Style.space(320))
    contentHeight: managePopup.fittedContentHeight(manageColumn.implicitHeight)

    // Manage-popup row glyphs — swap freely.
    readonly property string iconHiddenGlyph: ""
    readonly property string iconVisibleGlyph: ""

    PanelKeyCatcher {
      anchors.fill: parent
      onCloseRequested: root.close()

    Column {
      id: manageColumn
      anchors.fill: parent
      // Same section rhythm as the bluetooth panel's content column.
      spacing: Style.space(14)

      // Same hero arrangement as the audio panel: display-size glyph, title,
      // and an auto-uppercased letter-spaced caption (PanelHero's meta).
      PanelHero {
        width: manageColumn.width
        title: "Tray"
        meta: "Pin, hide, or drag on the bar"
        foreground: root.foreground
        fontFamily: root.fontFamily
        iconComponent: Component {
          Text {
            text: "󱊖"
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Math.round(Style.font.display * 1.2)
          }
        }
      }

      PanelSeparator {
        foreground: root.foreground
      }

      // The section header row and its icon rows form one tight block,
      // spaced like the wifi panel's network list (Style.space(4) between
      // rows); the outer column's looser section rhythm stays above it.
      Column {
        width: manageColumn.width
        spacing: Style.space(4)

        Item {
          width: parent.width
          implicitHeight: Math.max(hideIconsLabel.implicitHeight, hideIconsSwitch.implicitHeight)

          // Switch first, then the wifi-style all-caps section label.
          ToggleSwitch {
            id: hideIconsSwitch
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            checked: root.showTrayIcons
            foreground: root.foreground
            onToggled: root.persistState({ showTrayIcons: !root.showTrayIcons })
          }

          PanelSectionHeader {
            id: hideIconsLabel
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: hideIconsSwitch.right
            anchors.leftMargin: Style.space(10)
            anchors.right: parent.right
            text: "SHOW SYSTEM ICONS"
            foreground: root.foreground
            fontFamily: root.fontFamily
            elide: Text.ElideRight
          }
        }

        Text {
          visible: root.allItems.length === 0
          text: "No system tray icons reporting."
          color: Qt.darker(root.foreground, 1.5)
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          font.italic: true
        }

        Repeater {
          model: root.allItems
        // Built like the wifi panel's network rows: a CursorSurface that
        // lights up as one hoverable button, icon at the far left, title,
        // and a status glyph in a fixed slot at the far right. Clicking
        // anywhere on the row toggles the icon's hidden state.
        delegate: CursorSurface {
          id: rowRoot
          required property var modelData
          required property int index
          width: manageColumn.width
          implicitHeight: rowBody.implicitHeight
          hasCursor: iconRowMouse.containsMouse && root.showTrayIcons
          foreground: root.foreground
          // Grayed out while the master switch hides them all (inert too) or
          // while this icon is individually hidden (still clickable, so it
          // can be brought back).
          opacity: !root.showTrayIcons || isHidden ? 0.4 : 1.0
          enabled: root.showTrayIcons

          readonly property string itemId: String(modelData.id || "")
          readonly property string displayName: {
            var t = String(modelData.title || "").trim()
            if (t) return t
            var tt = String(modelData.tooltipTitle || "").trim()
            if (tt) return tt
            var id = String(modelData.id || "")
            var slash = id.lastIndexOf("/")
            return slash !== -1 ? id.substring(slash + 1) : (id || "Unknown")
          }
          readonly property bool isHidden: root.hiddenIds.indexOf(itemId) !== -1
          readonly property bool isPinned: root.pinnedIds.indexOf(itemId) !== -1

          MouseArea {
            id: iconRowMouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: root.toggleHide(rowRoot.itemId)
          }

          Item {
            id: rowBody
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: Style.space(10)
            anchors.rightMargin: Style.space(10)
            implicitHeight: Math.max(rowIcon.height, rowTitle.implicitHeight, rightGlyph.implicitHeight) + Style.spacing.rowPaddingX

            TrayIcon {
              id: rowIcon
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              width: Style.font.title
              height: Style.font.title
              icon: rowRoot.modelData.icon
            }

            Text {
              id: rowTitle
              anchors.left: rowIcon.right
              anchors.leftMargin: Style.space(10)
              anchors.right: pinGlyph.left
              anchors.rightMargin: Style.space(8)
              anchors.verticalCenter: parent.verticalCenter
              text: rowRoot.displayName
              textFormat: Text.PlainText
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              elide: Text.ElideRight
            }

            Text {
              id: pinGlyph
              anchors.right: rightGlyph.left
              anchors.verticalCenter: parent.verticalCenter
              width: Style.space(22)
              horizontalAlignment: Text.AlignHCenter
              text: "\uf08d"
              color: rowRoot.isPinned ? Commons.Color.accent : Qt.darker(root.foreground, 1.4)
              font.family: root.fontFamily
              font.pixelSize: Style.font.subtitle

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.togglePin(rowRoot.itemId)
              }
            }

            Item {
              id: rightGlyph
              width: Style.space(22)
              implicitHeight: rightGlyphText.implicitHeight
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter

              Text {
                id: rightGlyphText
                width: parent.width
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: Text.AlignHCenter
                text: rowRoot.isHidden ? managePopup.iconHiddenGlyph : managePopup.iconVisibleGlyph
                color: Qt.darker(root.foreground, 1.4)
                font.family: root.fontFamily
                font.pixelSize: Style.font.subtitle
              }
            }
          }
        }
      }
      }
    }
    }
  }

  QsMenuOpener {
    id: trayMenuOpener
    menu: root.activeTrayItem ? root.activeTrayItem.menu : null
  }

  // KeyboardPanel for the same reasons as the manage popup: an xdg-popup can
  // never take layer keyboard focus, so Escape could not close the app menu.
  // The fullscreen overlay also takes the pointer off the bar icon, which is
  // what used to let a stray tooltip pop up on top of the open menu.
  KeyboardPanel {
    id: trayMenuPopup
    anchorItem: root.activeTrayAnchor || root
    owner: root
    bar: root.bar
    open: root.trayMenuOpen
    // The card fades out over 140ms (visible stays true for that whole time),
    // so resetting on "open" would swap a live submenu for the root menu
    // mid-fade. Wait for the fade to actually finish. Switching to a different
    // tray item still resets immediately, from openTrayMenu() itself.
    onVisibleChanged: if (!visible) root.resetTrayMenu()
    padding: Style.space(8)
    borderSpec: Border.surfaceSpec("popups", "border",
      Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.45), Math.max(1, Style.space(2)))
    contentWidth: trayMenuPopup.fittedContentWidth(Style.space(232))
    contentHeight: trayMenuPopup.fittedContentHeight(menuHeaderHeight + trayMenuColumn.implicitHeight, Style.space(420))

    // Column skips invisible children but keeps reporting their height, so
    // read the header's extent through its own visibility.
    readonly property int menuHeaderHeight: menuHeader.visible ? menuHeader.implicitHeight : 0

    PanelKeyCatcher {
      anchors.fill: parent
      onCloseRequested: root.close()

    Column {
      id: trayMenuLayout
      anchors.fill: parent
      spacing: 0

      // Header for a drilled-into submenu: names where we are and walks back
      // out. Pinned above the Flickable so the way back stays reachable in a
      // submenu taller than the card. Only present below the root level.
      Column {
        id: menuHeader
        visible: root.submenuDepth > 0
        width: trayMenuLayout.width
        spacing: 0

        Item {
          id: menuBackRow
          width: menuHeader.width
          implicitHeight: Style.space(30)

          Rectangle {
            anchors.fill: parent
            radius: Math.max(2, Style.cornerRadius)
            color: backMouse.containsMouse ? Style.hoverFillFor(root.foreground, root.foreground) : "transparent"
          }

          Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            width: Style.space(22)
            horizontalAlignment: Text.AlignHCenter
            text: "‹"
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
          }

          Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: Style.space(28)
            anchors.right: parent.right
            anchors.rightMargin: Style.space(10)
            text: root.currentTitle
            textFormat: Text.PlainText
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            elide: Text.ElideRight
          }

          MouseArea {
            id: backMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              if (root.menuLevelSettling) return
              // Reset before the model swap so the parent level shows from
              // the top (same ordering as the row delegate below).
              trayMenuFlick.contentY = 0
              root.leaveSubmenu()
            }
          }
        }

        Item {
          width: menuHeader.width
          implicitHeight: Style.space(11)

          Rectangle {
            anchors.left: parent.left
            anchors.leftMargin: Style.space(10)
            anchors.right: parent.right
            anchors.rightMargin: Style.space(10)
            anchors.verticalCenter: parent.verticalCenter
            height: 1
            color: Color.popups.border
            opacity: 0.45
          }
        }
      }

      Flickable {
        id: trayMenuFlick
        width: trayMenuLayout.width
        height: trayMenuLayout.height - trayMenuPopup.menuHeaderHeight
        contentWidth: width
        contentHeight: trayMenuColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        interactive: contentHeight > height

        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
          id: trayMenuColumn
          width: trayMenuFlick.width
          spacing: 0

          Repeater {
            model: root.currentChildren

            delegate: Item {
              id: menuRow
              required property var modelData
              required property int index

              readonly property string rowText: String(modelData.text || "")
              readonly property string activeTitle: root.activeTrayItem ? String(root.activeTrayItem.title || root.activeTrayItem.id || "") : ""
              // Both only ever describe the root menu; inside a submenu the
              // first rows are real entries and must not be swallowed.
              readonly property bool atRoot: root.submenuDepth === 0
              readonly property bool rootTitleEntry: atRoot && index === 0 && modelData.hasChildren && rowText.toLowerCase() === activeTitle.toLowerCase()
              readonly property bool leadingSeparator: atRoot && modelData.isSeparator && index <= 1
              readonly property bool hiddenRow: rootTitleEntry || leadingSeparator

              visible: !hiddenRow
              width: trayMenuColumn.width
              implicitHeight: hiddenRow ? 0 : (modelData.isSeparator ? Style.space(11) : Style.space(30))
              opacity: modelData.enabled ? 1.0 : 0.45

              Rectangle {
                visible: menuRow.modelData.isSeparator
                anchors.left: parent.left
                anchors.leftMargin: Style.space(10)
                anchors.right: parent.right
                anchors.rightMargin: Style.space(10)
                anchors.verticalCenter: parent.verticalCenter
                height: 1
                color: Color.popups.border
                opacity: 0.45
              }

              Rectangle {
                visible: !menuRow.modelData.isSeparator
                anchors.fill: parent
                radius: Math.max(2, Style.cornerRadius)
                color: rowMouse.containsMouse && menuRow.modelData.enabled ? Style.hoverFillFor(root.foreground, root.foreground) : "transparent"
              }

              Text {
                visible: !menuRow.modelData.isSeparator && menuRow.modelData.buttonType !== QsMenuButtonType.None
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                width: Style.space(22)
                horizontalAlignment: Text.AlignHCenter
                text: menuRow.modelData.checkState === Qt.Checked ? "\uf00c" : ""
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
              }

              Image {
                id: menuIcon
                visible: !menuRow.modelData.isSeparator && String(menuRow.modelData.icon || "") !== ""
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: Style.space(24)
                width: Style.space(16)
                height: Style.space(16)
                fillMode: Image.PreserveAspectFit
                // Decode at physical pixels: IconImage uses the logical size,
                // which leaves PNG icons upscaled and blurry on HiDPI.
                sourceSize.width: width * Screen.devicePixelRatio
                sourceSize.height: height * Screen.devicePixelRatio
                source: menuRow.modelData.icon
              }

              Text {
                visible: !menuRow.modelData.isSeparator
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: menuIcon.visible ? Style.space(46) : Style.space(28)
                anchors.right: submenuGlyph.left
                anchors.rightMargin: Style.space(8)
                text: menuRow.rowText
                textFormat: Text.PlainText
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
                elide: Text.ElideRight
              }

              Text {
                id: submenuGlyph
                visible: !menuRow.modelData.isSeparator && menuRow.modelData.hasChildren
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: Style.space(10)
                text: "›"
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
              }

              MouseArea {
                id: rowMouse
                anchors.fill: parent
                hoverEnabled: true
                enabled: !menuRow.modelData.isSeparator && menuRow.modelData.enabled
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                  if (root.menuLevelSettling) return
                  if (menuRow.modelData.hasChildren) {
                    // Reset scroll BEFORE swapping the model: the swap
                    // destroys this delegate synchronously and ids stop
                    // resolving after.
                    trayMenuFlick.contentY = 0
                    root.enterSubmenu(menuRow.modelData, menuRow.rowText)
                  } else {
                    menuRow.modelData.triggered()
                    root.close()
                  }
                }
              }
            }
          }
        }
      }
    }
    }
  }

  // Renders a tray icon, recoloring symbolic icons to the bar foreground so
  // they stay visible on any theme (a raw symbolic icon keeps its baked-in
  // fill and disappears against a matching background).
  component TrayIcon: Item {
    id: trayIconRoot
    required property var icon
    readonly property bool symbolic: root.iconIsSymbolic(icon)

    Image {
      id: trayIconImage
      anchors.fill: parent
      fillMode: Image.PreserveAspectFit
      // Decode at physical pixels: IconImage uses the logical size,
      // which leaves PNG icons upscaled and blurry on HiDPI displays.
      sourceSize.width: Math.round(Math.min(width, height) * Screen.devicePixelRatio)
      sourceSize.height: Math.round(Math.min(width, height) * Screen.devicePixelRatio)
      source: root.trayIconSource(trayIconRoot.icon)
      // Kept as a hidden layer so the effect can sample it as a texture.
      visible: !trayIconRoot.symbolic
      layer.enabled: trayIconRoot.symbolic
    }

    // Paint the foreground through the icon's alpha. MultiEffect's colorization
    // keeps the source's lightness, so a dark fill stayed dark on a dark bar.
    Rectangle {
      anchors.fill: trayIconImage
      color: root.foreground
      visible: trayIconRoot.symbolic
      layer.enabled: trayIconRoot.symbolic
      layer.effect: MultiEffect {
        maskEnabled: true
        maskSource: trayIconImage
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
      }
    }
  }

  // The tray section's place in the drawer: the bar parents its widgets here.
  // Empty, it takes no room.
  component SectionArea: Item {
    id: sectionArea
    implicitWidth: childrenRect.width
    implicitHeight: childrenRect.height

    Component.onCompleted: root.sectionHost = sectionArea
    // The bar can tear this area down after the widget itself is gone
    // (a plugin rescan destroys them in its own order), so unregister
    // only while the widget is still there to unregister from.
    Component.onDestruction: if (root && root.sectionHost === sectionArea) root.sectionHost = null
  }

  component TrayItem: Item {
    id: trayItemRoot

    required property var modelData
    // Which strip it is laid out in: "pinned" or "drawer".
    property string zone: "drawer"
    readonly property string itemId: String(modelData.id || "")

    visible: modelData.status !== Status.Passive
    implicitWidth: visible ? root.trayItemExtent : 0
    implicitHeight: visible ? root.trayItemExtent : 0
    opacity: root.iconDragActive && root.iconDragItem === trayItemRoot ? 0.22 : 1

    Component.onCompleted: root.registerIconDelegate(trayItemRoot)
    Component.onDestruction: if (root) root.unregisterIconDelegate(trayItemRoot)

    function displayMenu(mouse) {
      root.openTrayMenu(trayItemRoot.modelData, trayItemRoot, mouse)
    }

    // The overlay holds left presses to tell a click from a drag, so a left
    // click arrives here from it rather than through the MouseArea below.
    function primaryClick(mouse) {
      if (trayItemRoot.modelData.onlyMenu) trayItemRoot.displayMenu(mouse)
      else trayItemRoot.modelData.activate()
    }

    TrayIcon {
      x: Math.round((parent.width - width) / 2)
      y: Math.round((parent.height - height) / 2)
      width: Style.bar.iconSize
      height: Style.bar.iconSize
      icon: trayItemRoot.modelData.icon
    }

    MouseArea {
      id: mouseArea
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      // No tooltips while one of the tray's own panels is up, or mid-drag.
      onEntered: {
        if (root.trayMenuOpen || root.managePopupOpen || root.iconDragActive) return
        if (root.bar) root.bar.showTooltip(trayItemRoot, root.trayTooltip(modelData))
      }
      onExited: if (root.bar) root.bar.hideTooltip(trayItemRoot)
      onPressed: function(mouse) {
        if (mouse.button === Qt.RightButton) {
          trayItemRoot.displayMenu(mouse)
          mouse.accepted = true
        }
      }
      onClicked: function(mouse) {
        if (mouse.button === Qt.RightButton) {
          mouse.accepted = true
        } else if (mouse.button === Qt.MiddleButton) {
          trayItemRoot.modelData.secondaryActivate()
        } else {
          trayItemRoot.primaryClick(mouse)
        }
      }
      onWheel: function(wheel) {
        trayItemRoot.modelData.scroll(wheel.angleDelta.y, false)
      }
    }

    readonly property bool tooltipHovered: visible && opacity > 0 && mouseArea.containsMouse
      && !root.trayMenuOpen && !root.managePopupOpen
  }
}

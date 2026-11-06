function text(value) {
  return String(value || "").toLowerCase()
}

function itemNamed(item, name) {
  if (!item) return false
  return text(item.id).indexOf(name) !== -1
    || text(item.title).indexOf(name) !== -1
    || text(item.tooltipTitle).indexOf(name) !== -1
}

function entryId(entry) {
  if (typeof entry === "string") return entry
  if (entry && typeof entry === "object") {
    var id = entry.id
    if (id !== undefined && id !== null && String(id) !== "") return String(id)
  }
  return ""
}

function layoutHasWidget(layout, id) {
  var sections = ["left", "centerBegin", "center", "centerEnd", "right", "tray"]
  for (var s = 0; s < sections.length; s++) {
    var entries = layout && layout[sections[s]]
    if (!Array.isArray(entries)) continue
    for (var i = 0; i < entries.length; i++) {
      if (entryId(entries[i]) === id) return true
    }
  }
  return false
}

// A bar widget that stands in for an app's tray item takes its place: the app's
// own icon would only show the same thing twice.
var widgetsForTrayItems = [
  { widget: "omarchy.dropbox", item: "dropbox" },
  { widget: "superwhisper.panel", item: "superwhisper" }
]

// LocalSend's item shows no state, offers only Open and Quit, and its primary
// click is a no-op, so Share > Receive is the whole surface. Hiding it by hand
// doesn't stick either: LocalSend picks a fresh tray id every launch.
function ownedByOmarchy(item, layout) {
  if (itemNamed(item, "localsend")) return true
  for (var i = 0; i < widgetsForTrayItems.length; i++) {
    var owner = widgetsForTrayItems[i]
    if (itemNamed(item, owner.item) && layoutHasWidget(layout, owner.widget)) return true
  }
  return false
}

// The stretch of the tray section, from `start` and `length` long along the
// bar, that the drawer's clip, from `clipStart` and `clipLength` long, shows:
// { start, length }, or null while it shows none of it. An empty section
// shows once it is within a pixel of the clip's edge, as the drawer eases to
// rest.
function shownSpan(clipStart, clipLength, start, length) {
  var from = Math.max(start, clipStart)
  var to = Math.min(start + length, clipStart + clipLength)
  if (to < from) {
    if (from - to > 1) return null
    from = to
  }
  return { start: from, length: to - from }
}

// QML can hand a settings array across property boundaries as a variant-list
// proxy: typeof "object", but Array.isArray false and array methods missing.
// Every settings-derived list is copied into a real array before use.
function asList(value) {
  if (Array.isArray(value)) return value
  if (value && typeof value === "object" && typeof value.length === "number") {
    var out = []
    for (var i = 0; i < value.length; i++) out.push(value[i])
    return out
  }
  return []
}

function stringList(value) {
  return asList(value).map(String)
}

// Sort items carrying an `id` by a persisted id list. Ids not in the list keep
// their arrival order after every listed one, so a newly started app appears at
// the end instead of shuffling what was arranged.
function sortByOrder(items, order) {
  var ids = stringList(order)
  return asList(items).map(function(item, index) {
    var at = ids.indexOf(String(item && item.id || ""))
    return { item: item, rank: at === -1 ? ids.length + index : at }
  }).sort(function(a, b) {
    return a.rank - b.rank
  }).map(function(row) {
    return row.item
  })
}

function insertedBefore(ids, id, beforeId) {
  var next = ids.filter(function(other) { return other !== id })
  var at = beforeId ? next.indexOf(String(beforeId)) : -1
  if (at === -1) next.push(id)
  else next.splice(at, 0, id)
  return next
}

// Where a status icon dragged to `axis` along the bar lands:
//   { zone: "hidden" }                         pulled off the bar
//   { zone: "pinned"|"drawer", beforeId, markerAt }  among that zone's icons
//   null                                       nowhere (the release is a no-op)
// `outside` is how far the pointer is past the bar across it. `tray`, `pinned`
// and `drawer` are { start, length } along the bar; `rows` the icons as
// { id, zone, start, length }. A beforeId of "" means the end of the zone.
function iconDrop(args) {
  if (args.outside >= args.removeDistance) return { zone: "hidden" }

  var axis = args.axis
  var tray = args.tray
  if (axis < tray.start || axis > tray.start + tray.length) return null

  var pinned = args.pinned
  var zone = pinned.length > 0 && axis >= pinned.start && axis <= pinned.start + pinned.length
    ? "pinned" : "drawer"
  var rows = asList(args.rows).filter(function(row) {
    return row.zone === zone && row.id !== args.draggedId
  }).sort(function(a, b) {
    return a.start - b.start
  })

  if (rows.length === 0) {
    var area = zone === "pinned" ? pinned : args.drawer
    return { zone: zone, beforeId: "", markerAt: area.start + area.length / 2 }
  }

  var best = null
  for (var i = 0; i < rows.length; i++) {
    var row = rows[i]
    var end = row.start + row.length
    var after = Math.abs(axis - end) < Math.abs(axis - row.start)
    var distance = Math.abs(axis - (after ? end : row.start))
    if (best && distance >= best.distance) continue
    best = {
      distance: distance,
      markerAt: after ? end : row.start,
      beforeId: after ? (rows[i + 1] ? rows[i + 1].id : "") : row.id
    }
  }
  return { zone: zone, beforeId: best.beforeId, markerAt: best.markerAt }
}

// The tray's next { pinned, hidden, order } once icon `id` has been dropped.
// An icon is in one place only. Ids of apps not running stay in the lists, so
// an app keeps its place across restarts. `shownDrawer` is the drawer's current
// visual order: an icon that was never arranged has no place in `order` until
// its first move, so the visual order is folded in before anything is inserted.
function moveIcon(state, id, drop, shownDrawer) {
  var key = String(id)
  var without = function(ids) {
    return stringList(ids).filter(function(other) { return other !== key })
  }
  var pinned = without(state.pinned)
  var hidden = without(state.hidden)
  var order = stringList(state.order)
  stringList(shownDrawer).forEach(function(other) {
    if (order.indexOf(other) === -1) order.push(other)
  })

  if (drop.zone === "hidden") hidden.push(key)
  else if (drop.zone === "pinned") pinned = insertedBefore(pinned, key, drop.beforeId)
  else order = insertedBefore(order, key, drop.beforeId)

  return { pinned: pinned, hidden: hidden, order: order }
}

if (typeof module !== "undefined") {
  module.exports = {
    shownSpan: shownSpan,
    itemNamed: itemNamed,
    entryId: entryId,
    layoutHasWidget: layoutHasWidget,
    ownedByOmarchy: ownedByOmarchy,
    asList: asList,
    stringList: stringList,
    sortByOrder: sortByOrder,
    iconDrop: iconDrop,
    moveIcon: moveIcon
  }
}

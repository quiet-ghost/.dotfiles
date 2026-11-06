const test = require("node:test")
const assert = require("node:assert/strict")
const TrayModel = require("../TrayModel.js")

const rows = [
  { id: "a", zone: "drawer", start: 100, length: 20 },
  { id: "b", zone: "drawer", start: 120, length: 20 },
  { id: "c", zone: "drawer", start: 140, length: 20 },
  { id: "p", zone: "pinned", start: 180, length: 20 }
]

function dropAt(axis, overrides) {
  return TrayModel.iconDrop({
    axis,
    outside: 0,
    removeDistance: 48,
    tray: { start: 80, length: 120 },
    pinned: { start: 180, length: 20 },
    drawer: { start: 100, length: 60 },
    rows,
    draggedId: "a",
    ...overrides
  })
}

test("a drop near an icon's start lands before it", () => {
  assert.deepEqual(dropAt(141), { zone: "drawer", beforeId: "c", markerAt: 140 })
})

test("a drop near the last icon's end lands at the end of the zone", () => {
  assert.deepEqual(dropAt(158), { zone: "drawer", beforeId: "", markerAt: 160 })
})

test("a drop on the pinned strip lands among the pinned icons", () => {
  assert.deepEqual(dropAt(182), { zone: "pinned", beforeId: "p", markerAt: 180 })
})

test("the dragged icon is not a drop target", () => {
  assert.deepEqual(dropAt(101, { draggedId: "a" }), { zone: "drawer", beforeId: "b", markerAt: 120 })
})

test("an empty pinned strip takes the drop", () => {
  const drop = dropAt(190, { rows: rows.filter((row) => row.zone === "drawer") })
  assert.deepEqual(drop, { zone: "pinned", beforeId: "", markerAt: 190 })
})

test("along the bar but past the tray, a release does nothing", () => {
  assert.equal(dropAt(40), null)
  assert.equal(dropAt(260), null)
})

test("pulled far enough off the bar, an icon is hidden wherever it is along it", () => {
  assert.deepEqual(dropAt(40, { outside: 48 }), { zone: "hidden" })
  assert.deepEqual(dropAt(140, { outside: 48 }), { zone: "hidden" })
})

test("a little way off the bar still counts as over the tray", () => {
  assert.equal(dropAt(141, { outside: 47 }).zone, "drawer")
})

test("reordering folds in an icon that was never arranged", () => {
  const next = TrayModel.moveIcon(
    { pinned: [], hidden: [], order: ["x"] },
    "c",
    { zone: "drawer", beforeId: "x" },
    ["x", "b", "c"]
  )
  assert.deepEqual(next.order, ["c", "x", "b"])
})

test("pinning takes the icon's place among the pinned and leaves hidden", () => {
  const next = TrayModel.moveIcon(
    { pinned: ["p"], hidden: ["a"], order: [] },
    "a",
    { zone: "pinned", beforeId: "p" },
    []
  )
  assert.deepEqual(next.pinned, ["a", "p"])
  assert.deepEqual(next.hidden, [])
})

test("dropping a pinned icon in the drawer unpins it", () => {
  const next = TrayModel.moveIcon(
    { pinned: ["a", "p"], hidden: [], order: ["b"] },
    "a",
    { zone: "drawer", beforeId: "" },
    ["b"]
  )
  assert.deepEqual(next.pinned, ["p"])
  assert.deepEqual(next.order, ["b", "a"])
})

test("hiding takes an icon out of pinned and keeps ids of stopped apps", () => {
  const next = TrayModel.moveIcon(
    { pinned: ["a", "stopped"], hidden: ["gone"], order: ["old"] },
    "a",
    { zone: "hidden" },
    []
  )
  assert.deepEqual(next.pinned, ["stopped"])
  assert.deepEqual(next.hidden, ["gone", "a"])
  assert.deepEqual(next.order, ["old"])
})

test("sortByOrder keeps unlisted items after the listed ones, in arrival order", () => {
  const items = [{ id: "n1" }, { id: "b" }, { id: "n2" }, { id: "a" }]
  assert.deepEqual(TrayModel.sortByOrder(items, ["a", "b"]).map((item) => item.id), ["a", "b", "n1", "n2"])
})

test("asList copies a variant-list proxy into a real array", () => {
  const proxy = { length: 2, 0: "a", 1: "b" }
  assert.deepEqual(TrayModel.asList(proxy), ["a", "b"])
  assert.deepEqual(TrayModel.asList(undefined), [])
})

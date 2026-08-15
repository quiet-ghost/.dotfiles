const test = require("node:test")
const assert = require("node:assert/strict")
const Model = require("../Model.js")

const RATES = { USD: 1, JPY: 159.33, EUR: 0.86573, GBP: 0.74042 }

test("parseAmount accepts grouped and decorated input", () => {
  assert.equal(Model.parseAmount("1,000.50"), 1000.5)
  assert.equal(Model.parseAmount("$20"), 20)
  assert.equal(Model.parseAmount("  ¥15,933 "), 15933)
  assert.equal(Model.parseAmount(""), null)
  assert.equal(Model.parseAmount("-3"), null)
})

test("parseRates reads Frankfurter v2 arrays and single pairs", () => {
  const many = Model.parseRates(JSON.stringify([
    { date: "2026-08-15", base: "USD", quote: "JPY", rate: 159.33 },
    { date: "2026-08-15", base: "USD", quote: "EUR", rate: 0.86573 }
  ]))
  assert.equal(many.ok, true)
  assert.equal(many.date, "2026-08-15")
  assert.equal(many.rates.USD, 1)
  assert.equal(many.rates.JPY, 159.33)
  assert.equal(many.rates.EUR, 0.86573)

  const one = Model.parseRates(JSON.stringify({
    date: "2026-08-15",
    base: "USD",
    quote: "JPY",
    rate: 159.33
  }))
  assert.equal(one.rates.JPY, 159.33)
})

test("convert usd to yen and back", () => {
  const yen = Model.convert(100, "USD", "JPY", RATES)
  assert.ok(Math.abs(yen - 15933) < 1e-9)
  const dollars = Model.convert(yen, "JPY", "USD", RATES)
  assert.ok(Math.abs(dollars - 100) < 1e-9)
})

test("convert via usd pivot", () => {
  const yen = Model.convert(10, "EUR", "JPY", RATES)
  assert.ok(Math.abs(yen - (10 * 159.33 / 0.86573)) < 1e-9)
})

test("missing quote does not invent a rate", () => {
  assert.equal(Model.convert(1, "USD", "CAD", RATES), null)
  assert.equal(Model.barLabel(1, "USD", "CAD", RATES), "USD → CAD")
})

test("swap keeps the converted amount in the new from currency", () => {
  const next = Model.swapState("USD", "JPY", 100, RATES)
  assert.equal(next.from, "JPY")
  assert.equal(next.to, "USD")
  assert.ok(Math.abs(next.amount - 15933) < 1e-9)
  assert.equal(next.amountText, "15,933")
})

test("format yen and dollars compactly", () => {
  assert.equal(Model.formatAmount(15933, "JPY", true), "15,933")
  assert.equal(Model.formatAmount(159.33, "JPY", false), "159.33")
  assert.equal(Model.formatAmount(1, "USD", true), "1")
  assert.equal(Model.formatAmount(1, "USD", false), "1.00")
  assert.equal(Model.barLabel(1, "USD", "JPY", RATES), "$1 → ¥159.33")
  assert.equal(Model.rateLabel("USD", "JPY", RATES), "1 USD = 159.33 JPY")
})

test("applyState defaults to usd yen", () => {
  assert.deepEqual(Model.applyState(""), { from: "USD", to: "JPY", amountText: "1" })
  assert.deepEqual(Model.applyState('{"from":"jpy","to":"usd","amount":"2500"}'), {
    from: "JPY",
    to: "USD",
    amountText: "2500"
  })
})

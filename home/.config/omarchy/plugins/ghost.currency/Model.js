var CURRENCIES = [
  { code: "USD", symbol: "$", name: "US Dollar", digits: 2 },
  { code: "JPY", symbol: "¥", name: "Japanese Yen", digits: 2 },
  { code: "EUR", symbol: "€", name: "Euro", digits: 2 },
  { code: "GBP", symbol: "£", name: "Pound Sterling", digits: 2 }
]

function currencyList() {
  return CURRENCIES.slice()
}

function currencyOptions() {
  var rows = []
  for (var i = 0; i < CURRENCIES.length; i++) {
    var item = CURRENCIES[i]
    rows.push({ value: item.code, label: item.code + " " + item.symbol })
  }
  return rows
}

function quoteCodes() {
  var codes = []
  for (var i = 0; i < CURRENCIES.length; i++) {
    if (CURRENCIES[i].code !== "USD") codes.push(CURRENCIES[i].code)
  }
  return codes
}

function currency(code) {
  var needle = String(code || "").trim().toUpperCase()
  for (var i = 0; i < CURRENCIES.length; i++) {
    if (CURRENCIES[i].code === needle) return CURRENCIES[i]
  }
  return null
}

function normalizeCode(code, fallback) {
  var needle = String(code || "").trim().toUpperCase()
  if (needle === "") return String(fallback || "USD")
  var found = currency(needle)
  return found ? found.code : needle
}

function symbolFor(code) {
  var found = currency(code)
  return found ? found.symbol : String(code || "")
}

function digitsFor(code) {
  var found = currency(code)
  return found ? found.digits : 2
}

function parseAmount(text) {
  var cleaned = String(text || "").trim().replace(/[,_\s]/g, "")
  cleaned = cleaned.replace(/^[^\d.-]+/, "")
  if (cleaned === "" || cleaned === "-" || cleaned === "." || cleaned === "-.") return null
  var value = Number(cleaned)
  if (!isFinite(value) || value < 0) return null
  return value
}

function parseRates(raw) {
  var rates = { USD: 1 }
  var date = ""
  try {
    var data = JSON.parse(String(raw || ""))
    var rows = []
    if (Array.isArray(data)) rows = data
    else if (data && typeof data === "object" && data.rate !== undefined) rows = [data]
    for (var i = 0; i < rows.length; i++) {
      var row = rows[i]
      if (!row || row.quote === undefined || row.rate === undefined) continue
      var quote = String(row.quote || "").trim().toUpperCase()
      var rate = Number(row.rate)
      if (quote === "" || !isFinite(rate) || rate <= 0) continue
      rates[quote] = rate
      if (row.date) date = String(row.date)
    }
  } catch (e) {
    return { date: "", rates: { USD: 1 }, ok: false }
  }
  return { date: date, rates: rates, ok: true }
}

function usdRate(rates, code) {
  var normalized = String(code || "").trim().toUpperCase()
  if (normalized === "USD") return 1
  if (!rates || rates[normalized] === undefined || rates[normalized] === null) return null
  var value = Number(rates[normalized])
  if (!isFinite(value) || value <= 0) return null
  return value
}

function rateFor(rates, from, to) {
  var source = String(from || "").trim().toUpperCase()
  var target = String(to || "").trim().toUpperCase()
  if (source === "" || target === "") return null
  if (source === target) return 1
  var fromUsd = usdRate(rates, source)
  var toUsd = usdRate(rates, target)
  if (fromUsd === null || toUsd === null) return null
  return toUsd / fromUsd
}

function convert(amount, from, to, rates) {
  var value = Number(amount)
  if (!isFinite(value)) return null
  var rate = rateFor(rates, from, to)
  if (rate === null) return null
  return value * rate
}

function groupInt(value) {
  return String(value).replace(/\B(?=(\d{3})+(?!\d))/g, ",")
}

function rateDigits(rate) {
  var value = Math.abs(Number(rate) || 0)
  if (value >= 100) return 2
  if (value >= 1) return 4
  return 6
}

function formatNumber(value, digits, compact) {
  var number = Number(value)
  if (!isFinite(number)) return ""
  var places = Math.max(0, Number(digits) || 0)
  var sign = number < 0 ? "-" : ""
  var abs = Math.abs(number)
  var factor = Math.pow(10, places)
  var rounded = Math.round(abs * factor) / factor
  var fixed = rounded.toFixed(places)
  var parts = fixed.split(".")
  var head = groupInt(parts[0])
  if (places === 0) return sign + head
  var frac = parts[1] || ""
  if (compact) {
    frac = frac.replace(/0+$/, "")
    return frac === "" ? sign + head : sign + head + "." + frac
  }
  return sign + head + "." + frac
}

function formatAmount(value, code, compact) {
  return formatNumber(value, digitsFor(code), compact === true)
}

function formatRate(rate) {
  return formatNumber(rate, rateDigits(rate), true)
}

function rateLabel(from, to, rates) {
  var rate = rateFor(rates, from, to)
  if (rate === null) return ""
  return "1 " + normalizeCode(from, from) + " = " + formatRate(rate) + " " + normalizeCode(to, to)
}

function barLabel(amount, from, to, rates) {
  var converted = convert(amount, from, to, rates)
  if (converted === null) return normalizeCode(from, "USD") + " → " + normalizeCode(to, "JPY")
  return symbolFor(from) + formatAmount(amount, from, true) + " → " + symbolFor(to) + formatAmount(converted, to, true)
}

function swapState(from, to, amount, rates) {
  var converted = convert(amount, from, to, rates)
  var nextFrom = normalizeCode(to, "JPY")
  var nextTo = normalizeCode(from, "USD")
  if (converted === null) {
    return {
      from: nextFrom,
      to: nextTo,
      amount: amount,
      amountText: amount === null || amount === undefined ? "" : String(amount)
    }
  }
  return {
    from: nextFrom,
    to: nextTo,
    amount: converted,
    amountText: formatAmount(converted, nextFrom, true)
  }
}

function applyState(raw) {
  var parsed = {}
  try {
    parsed = JSON.parse(String(raw || "{}")) || {}
  } catch (e) {
    parsed = {}
  }
  var from = normalizeCode(parsed.from, "USD")
  var to = normalizeCode(parsed.to, "JPY")
  if (from === to) to = from === "USD" ? "JPY" : "USD"
  var amountText = parsed.amountText !== undefined ? String(parsed.amountText) : String(parsed.amount !== undefined ? parsed.amount : "1")
  if (parseAmount(amountText) === null) amountText = "1"
  return { from: from, to: to, amountText: amountText }
}

function ratesUrl() {
  return "https://api.frankfurter.dev/v2/rates?base=USD&quotes=" + quoteCodes().join(",")
}

if (typeof module !== "undefined") {
  module.exports = {
    CURRENCIES: CURRENCIES,
    currencyList: currencyList,
    currencyOptions: currencyOptions,
    quoteCodes: quoteCodes,
    currency: currency,
    normalizeCode: normalizeCode,
    symbolFor: symbolFor,
    digitsFor: digitsFor,
    parseAmount: parseAmount,
    parseRates: parseRates,
    usdRate: usdRate,
    rateFor: rateFor,
    convert: convert,
    formatNumber: formatNumber,
    formatAmount: formatAmount,
    formatRate: formatRate,
    rateLabel: rateLabel,
    barLabel: barLabel,
    swapState: swapState,
    applyState: applyState,
    ratesUrl: ratesUrl
  }
}

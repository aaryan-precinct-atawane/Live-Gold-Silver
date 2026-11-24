import { Controller } from "@hotwired/stimulus"

// Keeps the practice trading desk live:
// - every second, asks the server (GET /trade/live) for Binance prices and the
//   live P&L of each open trade, and updates the numbers on the page
// - draws the live price chart for the selected metal
// - counts down each open trade to its expiry
// When the server says a trade has closed (or a new one appeared), it refreshes
// the page so the balance and history update. The server is always the one that
// decides prices and P&L; this file only displays them.
const CHART_WINDOW_MS = 5 * 60 * 1000

const inrFormat = new Intl.NumberFormat("en-IN", { style: "currency", currency: "INR", minimumFractionDigits: 2 })
const usdFormat = new Intl.NumberFormat("en-US", { style: "currency", currency: "USD", minimumFractionDigits: 2 })

export default class extends Controller {
  static targets = ["status", "balance", "equity", "priceUsd", "priceInr", "chart", "chartTitle", "metalInput", "trade"]
  static values = { liveUrl: String, history: Object, interval: { type: Number, default: 1000 } }

  connect() {
    this.history = { gold: [], silver: [], ...structuredClone(this.historyValue) }
    this.serverOffset = 0      // server clock minus browser clock, in ms
    this.lastPrices = {}
    this.busy = false

    // Redraw the chart whenever its size changes (window resize, phone rotation).
    this.resizeObserver = new ResizeObserver(() => this.drawChart())
    if (this.hasChartTarget) this.resizeObserver.observe(this.chartTarget)

    this.drawChart()
    this.poll()
    this.pollTimer = setInterval(() => this.poll(), this.intervalValue)
    this.clockTimer = setInterval(() => this.tickClock(), 250)
  }

  disconnect() {
    clearInterval(this.pollTimer)
    clearInterval(this.clockTimer)
    this.resizeObserver.disconnect()
  }

  async poll() {
    if (this.busy) return // the previous request is still waiting; don't pile up
    this.busy = true
    try {
      const response = await fetch(this.liveUrlValue, { headers: { Accept: "application/json" } })
      if (!response.ok) throw new Error(`HTTP ${response.status}`)
      this.apply(await response.json())
    } catch (error) {
      this.setStatus("Live prices delayed, retrying…", "delayed")
    } finally {
      this.busy = false
    }
  }

  apply(data) {
    this.serverOffset = data.server_time - Date.now()

    // A trade was settled on the server (or opened in another tab): refresh the page.
    const shownIds = this.tradeTargets.map((el) => Number(el.dataset.tradeId)).sort()
    const liveIds = data.open_trades.map((t) => t.id).sort()
    if (shownIds.join() !== liveIds.join()) {
      Turbo.visit(window.location.href, { action: "replace" })
      return
    }

    this.updatePrices(data)
    this.updateTrades(data)
    this.drawChart()

    const missing = Object.keys(data.prices).filter((m) => data.prices[m] === null)
    if (missing.length) {
      this.setStatus(`Live · Binance (${missing.join(", ")} delayed)`, "delayed")
    } else {
      this.setStatus("Live · Binance futures · updates every second", "live")
    }
  }

  updatePrices(data) {
    for (const [metal, price] of Object.entries(data.prices)) {
      if (price === null) continue

      const points = this.history[metal]
      points.push([data.server_time, price])
      while (points.length && points[0][0] < data.server_time - CHART_WINDOW_MS) points.shift()

      const previous = this.lastPrices[metal]
      this.lastPrices[metal] = price

      this.priceUsdTargets.filter((el) => el.dataset.metal === metal).forEach((el) => {
        el.textContent = usdFormat.format(price)
        if (previous !== undefined && previous !== price) this.flash(el, price > previous ? "up" : "down")
      })
      this.priceInrTargets.filter((el) => el.dataset.metal === metal).forEach((el) => {
        el.textContent = data.usd_inr_rate ? inrFormat.format(price * data.usd_inr_rate) : ""
      })
    }
  }

  updateTrades(data) {
    let openValue = 0
    for (const trade of data.open_trades) {
      const el = this.tradeTargets.find((t) => Number(t.dataset.tradeId) === trade.id)
      const stake = Number(el.dataset.stake)
      if (trade.pnl_inr === null) { openValue += stake; continue }

      openValue += stake + trade.pnl_inr
      el.querySelector("[data-role=price]").textContent = usdFormat.format(trade.price_usd)
      const pnl = el.querySelector("[data-role=pnl]")
      pnl.textContent = this.signedInr(trade.pnl_inr)
      pnl.className = `change change--${trade.pnl_inr > 0 ? "up" : trade.pnl_inr < 0 ? "down" : "flat"}`
      el.querySelector("[data-role=multiple]").textContent = `${trade.value_multiple.toFixed(2)}×`
    }

    this.balanceTarget.textContent = inrFormat.format(data.balance_inr)
    this.equityTarget.textContent = inrFormat.format(data.balance_inr + openValue)
  }

  // Countdown text and progress bar for each open trade, 4 times a second.
  tickClock() {
    const now = Date.now() + this.serverOffset
    for (const el of this.tradeTargets) {
      const opened = Number(el.dataset.openedAt)
      const expires = Number(el.dataset.expiresAt)
      const left = Math.max(0, expires - now)
      const seconds = Math.ceil(left / 1000)

      el.querySelector("[data-role=countdown]").textContent =
        left > 0 ? `${Math.floor(seconds / 60)}:${String(seconds % 60).padStart(2, "0")} left` : "Settling…"
      el.querySelector("[data-role=bar]").style.width = `${(left / (expires - opened)) * 100}%`
    }
  }

  get selectedMetal() {
    return this.metalInputTargets.find((input) => input.checked)?.value || "gold"
  }

  drawChart() {
    if (!this.hasChartTarget) return
    const metal = this.selectedMetal
    const name = metal.charAt(0).toUpperCase() + metal.slice(1)
    this.chartTitleTarget.textContent = `${name} · last 5 minutes`

    const points = this.history[metal] || []
    if (points.length < 2) {
      this.chartTarget.innerHTML = `<text x="50%" y="50%" text-anchor="middle" class="chart__empty">Collecting live prices…</text>`
      return
    }

    const entries = this.tradeTargets
      .filter((el) => el.dataset.metal === metal)
      .map((el) => ({ price: Number(el.dataset.entry), up: el.closest(".trade--up") !== null }))

    // Draw at the chart's real on-screen size so text and the dot aren't stretched.
    const box = this.chartTarget.getBoundingClientRect()
    const W = Math.round(box.width) || 600
    const H = Math.round(box.height) || 240
    const PAD = 14
    this.chartTarget.setAttribute("viewBox", `0 0 ${W} ${H}`)
    const prices = points.map((p) => p[1]).concat(entries.map((e) => e.price))
    let min = Math.min(...prices), max = Math.max(...prices)
    if (max - min < max * 0.0002) { const mid = (max + min) / 2; min = mid - mid * 0.0001; max = mid + mid * 0.0001 }
    const t0 = points[0][0], t1 = points[points.length - 1][0]

    const x = (t) => PAD + ((t - t0) / Math.max(1, t1 - t0)) * (W - 2 * PAD)
    const y = (p) => H - PAD - ((p - min) / (max - min)) * (H - 2 * PAD)

    const line = points.map(([t, p]) => `${x(t).toFixed(1)},${y(p).toFixed(1)}`).join(" ")
    const area = `${x(t0).toFixed(1)},${H - PAD} ${line} ${x(t1).toFixed(1)},${H - PAD}`
    const rising = points[points.length - 1][1] >= points[0][1]
    const last = points[points.length - 1]

    const entryLines = entries.map((e) =>
      `<line x1="${PAD}" x2="${W - PAD}" y1="${y(e.price).toFixed(1)}" y2="${y(e.price).toFixed(1)}"
             class="chart__entry chart__entry--${e.up ? "up" : "down"}" />`).join("")

    this.chartTarget.innerHTML = `
      <polygon points="${area}" class="chart__area chart__area--${metal}" />
      <polyline points="${line}" class="chart__line chart__line--${rising ? "up" : "down"}" />
      ${entryLines}
      <circle cx="${x(last[0]).toFixed(1)}" cy="${y(last[1]).toFixed(1)}" r="4" class="chart__dot" />
      <text x="${W - PAD}" y="${PAD + 4}" text-anchor="end" class="chart__label">${usdFormat.format(max)}</text>
      <text x="${W - PAD}" y="${H - PAD - 4}" text-anchor="end" class="chart__label">${usdFormat.format(min)}</text>`
  }

  setStatus(text, state) {
    if (!this.hasStatusTarget) return
    this.statusTarget.textContent = text
    this.statusTarget.dataset.state = state
  }

  flash(el, direction) {
    el.classList.remove("flash-up", "flash-down")
    void el.offsetWidth // restart the CSS animation
    el.classList.add(`flash-${direction}`)
  }

  signedInr(amount) {
    const sign = amount > 0 ? "+" : amount < 0 ? "-" : ""
    return `${sign}${inrFormat.format(Math.abs(amount))}`
  }
}

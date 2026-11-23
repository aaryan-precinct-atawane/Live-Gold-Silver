import { Controller } from "@hotwired/stimulus"

// Reloads the current page every few seconds so new ticker prices appear.
// Because the page uses Turbo "morph" refreshes, only changed numbers update.
export default class extends Controller {
  static values = { interval: { type: Number, default: 5000 } }

  connect() {
    this.timer = setInterval(() => this.refresh(), this.intervalValue)
  }

  disconnect() {
    clearInterval(this.timer)
  }

  refresh() {
    Turbo.visit(window.location.href, { action: "replace" })
  }
}

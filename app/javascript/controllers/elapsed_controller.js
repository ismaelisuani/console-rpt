import { Controller } from "@hotwired/stimulus"

// mm:ss since a moment (a reception or transmission that is going on)
export default class extends Controller {
  static values = { since: String }

  connect() {
    this.start = Date.parse(this.sinceValue)
    this.tick()
    this.timer = setInterval(() => this.tick(), 1000)
  }

  disconnect() {
    clearInterval(this.timer)
  }

  tick() {
    const seconds = Math.max(0, Math.floor((Date.now() - this.start) / 1000))
    const minutes = Math.floor(seconds / 60)
    this.element.textContent = `${String(minutes).padStart(2, "0")}:${String(seconds % 60).padStart(2, "0")}`
  }
}

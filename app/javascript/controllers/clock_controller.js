import { Controller } from "@hotwired/stimulus"

// Wall clock in the top bar, in the page language
export default class extends Controller {
  connect() {
    this.format = new Intl.DateTimeFormat(document.documentElement.lang, { hour: "2-digit", minute: "2-digit", second: "2-digit" })
    this.tick()
    this.timer = setInterval(() => this.tick(), 1000)
  }

  disconnect() {
    clearInterval(this.timer)
  }

  tick() {
    this.element.textContent = this.format.format(new Date())
  }
}

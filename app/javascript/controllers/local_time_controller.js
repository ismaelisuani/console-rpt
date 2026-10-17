import { Controller } from "@hotwired/stimulus"

// A server time shown in the browser's time zone and the page language
export default class extends Controller {
  static values = { format: { type: String, default: "time" } }

  connect() {
    const date = new Date(this.element.getAttribute("datetime"))
    const options = { hour: "2-digit", minute: "2-digit" }
    if (this.formatValue === "seconds") options.second = "2-digit"
    const today = new Date().toDateString() === date.toDateString()
    if (!today) Object.assign(options, { day: "2-digit", month: "2-digit" })
    this.element.textContent = new Intl.DateTimeFormat(document.documentElement.lang, options).format(date)
  }
}

import { Controller } from "@hotwired/stimulus"

// The eye button of a password field: shows or hides what was typed
export default class extends Controller {
  static targets = [ "input", "button", "shown", "hidden" ]
  static values = { showLabel: String, hideLabel: String }

  toggle() {
    const show = this.inputTarget.type === "password"
    this.inputTarget.type = show ? "text" : "password"
    this.shownTarget.hidden = !show
    this.hiddenTarget.hidden = show
    const label = show ? this.hideLabelValue : this.showLabelValue
    this.buttonTarget.title = label
    this.buttonTarget.setAttribute("aria-label", label)
    this.buttonTarget.setAttribute("aria-pressed", show)
    this.inputTarget.focus()
  }
}

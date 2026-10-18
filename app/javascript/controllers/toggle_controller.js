import { Controller } from "@hotwired/stimulus"

// Shows or hides a panel (the menu on small screens, the phone on the
// dispatch screen): with the hidden attribute, or with a CSS class when the
// panel is only hidden on some screen sizes
export default class extends Controller {
  static targets = [ "panel", "button" ]
  static values = { class: String }

  toggle() {
    let open
    if (this.classValue) {
      open = this.panelTarget.classList.toggle(this.classValue) === false
    } else {
      open = this.panelTarget.hidden
      this.panelTarget.hidden = !open
    }
    if (this.hasButtonTarget) this.buttonTarget.setAttribute("aria-expanded", open)
  }
}

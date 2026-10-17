import { Controller } from "@hotwired/stimulus"

// The dispatch screen: space bar PTT on the selected radios, listen all and
// mute all
export default class extends Controller {
  static targets = [ "radio" ]

  get radios() {
    return this.radioTargets.map(element => this.application.getControllerForElementAndIdentifier(element, "radio")).filter(Boolean)
  }

  keydown(event) {
    if (event.code !== "Space" || event.repeat || this.typing(event)) return
    const selected = this.radios.filter(radio => radio.selected)
    if (selected.length === 0) return
    event.preventDefault()
    selected.forEach(radio => radio.pttDown())
  }

  keyup(event) {
    if (event.code !== "Space" || this.typing(event)) return
    this.radios.forEach(radio => radio.pttUp())
  }

  connectAll() {
    this.radios.forEach(radio => { if (!radio.connected) radio.connectRadio() })
  }

  muteAll() {
    this.radios.forEach(radio => radio.mute())
  }

  typing(event) {
    return event.target.closest("input, textarea, select, [contenteditable]")
  }
}

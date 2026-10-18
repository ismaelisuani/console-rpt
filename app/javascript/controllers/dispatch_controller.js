import { Controller } from "@hotwired/stimulus"

// The dispatch screen's keyboard: arrows move the focus between the radio
// tiles; Space is PTT on the focused radio (or on the selected ones) while it
// is held. Also listen all and mute all.
export default class extends Controller {
  static targets = [ "radio" ]

  get radios() {
    return this.radioTargets.map(element => this.controllerFor(element)).filter(Boolean)
  }

  controllerFor(element) {
    return this.application.getControllerForElementAndIdentifier(element, "radio")
  }

  keydown(event) {
    if (this.typing(event)) return
    if (event.key.startsWith("Arrow")) return this.navigate(event)
    if (event.code !== "Space" || event.repeat) return

    const radios = this.pttRadios(event)
    if (radios.length === 0) return
    event.preventDefault()
    radios.forEach(radio => radio.pttDown())
  }

  keyup(event) {
    if (event.code !== "Space" || this.typing(event)) return
    if (this.radios.some(radio => radio.transmitting)) event.preventDefault()
    this.releaseAll()
  }

  // Window lost the focus while Space was held: never leave PTT stuck
  releaseAll() {
    this.radios.forEach(radio => radio.pttUp())
  }

  // The focused tile, else the selected ones (not when a button has the focus:
  // Space presses it)
  pttRadios(event) {
    const focused = this.radioTargets.find(element => element === document.activeElement)
    if (focused) return [ this.controllerFor(focused) ].filter(Boolean)
    if (event.target.closest("button, a, [role=button]")) return []
    return this.radios.filter(radio => radio.selected)
  }

  navigate(event) {
    const tiles = this.radioTargets.filter(element => element.offsetParent)
    if (tiles.length === 0) return
    event.preventDefault()
    const current = tiles.find(element => element.contains(document.activeElement))
    const next = current ? this.neighbour(current, tiles, event.key) : tiles[0]
    next?.focus()
    next?.scrollIntoView({ block: "nearest" })
  }

  // The closest tile in the arrow's direction, by position on the screen
  neighbour(current, tiles, key) {
    const from = this.center(current)
    let best = null
    let bestScore = Infinity
    tiles.forEach(tile => {
      if (tile === current) return
      const to = this.center(tile)
      const dx = to.x - from.x
      const dy = to.y - from.y
      const ahead = { ArrowRight: dx, ArrowLeft: -dx, ArrowDown: dy, ArrowUp: -dy }[key]
      if (ahead <= 1) return
      const aside = key === "ArrowRight" || key === "ArrowLeft" ? Math.abs(dy) : Math.abs(dx)
      const score = ahead + aside * 2
      if (score < bestScore) { best = tile; bestScore = score }
    })
    return best
  }

  center(element) {
    const box = element.getBoundingClientRect()
    return { x: box.left + box.width / 2, y: box.top + box.height / 2 }
  }

  connectAll() {
    this.radios.forEach(radio => { if (!radio.connected) radio.connectRadio() })
  }

  muteAll() {
    this.radios.forEach(radio => radio.mute())
  }

  typing(event) {
    return event.target.closest("input, textarea, select, [contenteditable], dialog")
  }
}

import { Controller } from "@hotwired/stimulus"

// The dispatch screen's keyboard and general PTT.
// - Arrows (or a click) focus a radio tile.
// - Space, while held: PTT on the radios included in the general PTT, or on
//   the focused radio when none is included. It never scrolls the page.
// - The general PTT bar shows which radios Space (or its button) talks on.
export default class extends Controller {
  static targets = [ "radio", "generalList", "generalButton", "spaceHint" ]

  connect() {
    // after the radio tiles' own controllers connect
    requestAnimationFrame(() => {
      this.restoreGeneral()
      this.updateGeneral()
    })
  }

  get radios() {
    return this.radioTargets.map(element => this.controllerFor(element)).filter(Boolean)
  }

  controllerFor(element) {
    return this.application.getControllerForElementAndIdentifier(element, "radio")
  }

  get included() {
    return this.radios.filter(radio => radio.selected)
  }

  keydown(event) {
    if (this.typing(event)) return
    if (event.key.startsWith("Arrow")) return this.navigate(event)
    if (event.code !== "Space") return
    // held Space repeats: none of it may scroll, nor press a focused button
    event.preventDefault()
    if (event.repeat) return
    this.pttRadios().forEach(radio => radio.pttDown())
  }

  keyup(event) {
    if (event.code !== "Space" || this.typing(event)) return
    event.preventDefault()
    this.releaseAll()
  }

  // Window lost the focus while Space was held: never leave PTT stuck
  releaseAll() {
    this.radios.forEach(radio => radio.pttUp())
  }

  pttRadios() {
    if (this.included.length) return this.included
    const focused = this.radioTargets.find(element => element.contains(document.activeElement))
    return focused ? [ this.controllerFor(focused) ].filter(Boolean) : []
  }

  // General PTT button
  generalDown(event) {
    event.preventDefault()
    this.generalButtonTarget.setPointerCapture?.(event.pointerId)
    this.included.forEach(radio => radio.pttDown())
  }

  generalUp() {
    this.included.forEach(radio => radio.pttUp())
  }

  // Which radios the general PTT talks on; kept per group in this browser
  updateGeneral() {
    if (!this.hasGeneralListTarget) return
    const included = this.included
    this.generalListTarget.replaceChildren(...included.map(radio => {
      const chip = document.createElement("span")
      chip.className = radio.connected ? "badge bg-accent text-white" : "badge bg-warn-soft text-warn-ink"
      chip.textContent = radio.connected ? radio.name : `${radio.name} · ${this.t("notListening")}`
      return chip
    }))
    const ready = included.some(radio => radio.connected)
    this.generalButtonTarget.disabled = !ready
    this.spaceHintTarget.textContent = included.length ? this.t("spaceGeneral") : this.t("spaceFocused")
    this.saveGeneral()
  }

  restoreGeneral() {
    let ids = []
    try { ids = JSON.parse(localStorage.getItem(this.storageKey)) || [] } catch {}
    this.radios.forEach(radio => { if (ids.includes(radio.idValue)) radio.setGeneral(true) })
  }

  saveGeneral() {
    try { localStorage.setItem(this.storageKey, JSON.stringify(this.included.map(radio => radio.idValue))) } catch {}
  }

  get storageKey() {
    return `dispatch-general-${this.element.dataset.group || "all"}`
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

  t(key) {
    return JSON.parse(document.getElementById("dispatch-strings").textContent)[key]
  }
}

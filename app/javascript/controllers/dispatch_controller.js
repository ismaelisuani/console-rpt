import { Controller } from "@hotwired/stimulus"

// The dispatch screen's keyboard and group PTT.
// - Arrows (or a click) focus a radio tile; a control inside it counts too.
// - Space, while held: PTT on the focused radio. Shift + Space (or the big
//   button): PTT on the radios included in the group PTT. Space never scrolls.
// - The bar shows where Space talks and which radios the group PTT includes.
export default class extends Controller {
  static targets = [ "radio", "generalList", "generalButton", "spaceHint", "focusedName" ]

  connect() {
    this.focusChanged = () => this.showFocused()
    document.addEventListener("focusin", this.focusChanged)
    document.addEventListener("focusout", this.focusChanged)
    // after the radio tiles' own controllers connect
    requestAnimationFrame(() => {
      this.restoreGeneral()
      this.updateGeneral()
      this.showFocused()
    })
  }

  disconnect() {
    document.removeEventListener("focusin", this.focusChanged)
    document.removeEventListener("focusout", this.focusChanged)
  }

  get focusedRadio() {
    const element = this.radioTargets.find(tile => tile.contains(document.activeElement))
    return element && this.controllerFor(element)
  }

  // "Space → <radio>" in the bar (after focus moves, so on the next frame)
  showFocused() {
    requestAnimationFrame(() => {
      if (!this.hasFocusedNameTarget) return
      const radio = this.focusedRadio
      this.focusedNameTarget.textContent = radio ? radio.name : this.t("noFocus")
      this.focusedNameTarget.classList.toggle("text-faint", !radio)
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
    this.pttRadios(event).forEach(radio => radio.pttDown())
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

  pttRadios(event) {
    if (event.shiftKey) return this.included
    const radio = this.focusedRadio
    return radio ? [ radio ] : []
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
    this.spaceHintTarget.textContent = included.length ? this.t("spaceGeneral") : ""
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

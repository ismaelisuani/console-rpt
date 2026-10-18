import { Controller } from "@hotwired/stimulus"

// A panel the user resizes: the activity log (height, top edge) or the phone
// (width, right edge), dragging the edge or the corner mark; the size is
// remembered in this browser.
export default class extends Controller {
  static values = {
    key: String,
    axis: { type: String, default: "y" },
    min: { type: Number, default: 64 },
    max: { type: Number, default: 0.7 }
  }

  connect() {
    const saved = this.load()
    if (saved) this.setSize(saved)
  }

  dragStart(event) {
    event.preventDefault()
    const start = this.horizontal ? event.clientX : event.clientY
    const startSize = this.size
    const move = moveEvent => {
      const position = this.horizontal ? moveEvent.clientX : moveEvent.clientY
      // the phone grows to the right; the activity log grows upwards
      this.setSize(startSize + (this.horizontal ? position - start : start - position))
    }
    const up = () => {
      window.removeEventListener("pointermove", move)
      window.removeEventListener("pointerup", up)
      this.save()
    }
    window.addEventListener("pointermove", move)
    window.addEventListener("pointerup", up)
  }

  get horizontal() {
    return this.axisValue === "x"
  }

  get size() {
    const box = this.element.getBoundingClientRect()
    return this.horizontal ? box.width : box.height
  }

  setSize(size) {
    const max = (this.horizontal ? window.innerWidth : window.innerHeight) * this.maxValue
    const value = `${Math.round(Math.min(Math.max(size, this.minValue), max))}px`
    // the width only applies on wide screens (CSS: md:w-(--panel-width))
    if (this.horizontal) this.element.style.setProperty("--panel-width", value)
    else this.element.style.height = value
  }

  load() {
    try { return parseFloat(localStorage.getItem(this.keyValue)) } catch { return null }
  }

  save() {
    try { localStorage.setItem(this.keyValue, Math.round(this.size)) } catch {}
  }
}

import { Controller } from "@hotwired/stimulus"

// A panel whose height the user changes: drag its top edge, or the arrows.
// The height is remembered in this browser.
export default class extends Controller {
  static values = { key: String, min: { type: Number, default: 64 }, step: { type: Number, default: 80 } }

  connect() {
    const saved = this.load()
    if (saved) this.setHeight(saved)
  }

  dragStart(event) {
    event.preventDefault()
    const startY = event.clientY
    const startHeight = this.element.getBoundingClientRect().height
    const move = moveEvent => this.setHeight(startHeight + startY - moveEvent.clientY)
    const up = () => {
      window.removeEventListener("pointermove", move)
      window.removeEventListener("pointerup", up)
      this.save()
    }
    window.addEventListener("pointermove", move)
    window.addEventListener("pointerup", up)
  }

  grow() {
    this.setHeight(this.element.getBoundingClientRect().height + this.stepValue)
    this.save()
  }

  shrink() {
    this.setHeight(this.element.getBoundingClientRect().height - this.stepValue)
    this.save()
  }

  setHeight(height) {
    const max = window.innerHeight * 0.7
    this.element.style.height = `${Math.round(Math.min(Math.max(height, this.minValue), max))}px`
  }

  load() {
    try { return parseFloat(localStorage.getItem(this.keyValue)) } catch { return null }
  }

  save() {
    try { localStorage.setItem(this.keyValue, parseFloat(this.element.style.height)) } catch {}
  }
}

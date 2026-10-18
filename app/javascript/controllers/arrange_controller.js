import { Controller } from "@hotwired/stimulus"

// Radio tiles arranged by the user: drag a tile by its grip to move it, drag
// its corner to resize it (in grid cells). Every change is saved.
export default class extends Controller {
  static targets = [ "tile" ]
  static values = { url: String, columns: Number, maxHeight: { type: Number, default: 3 } }

  // Moving
  arm(event) {
    event.currentTarget.closest("[data-arrange-target=tile]").draggable = true
  }

  dragStart(event) {
    this.dragged = event.target.closest("[data-arrange-target=tile]")
    if (!this.dragged) return
    event.dataTransfer.effectAllowed = "move"
    event.dataTransfer.setData("text/plain", this.dragged.dataset.radioId)
    this.dragged.classList.add("opacity-40")
  }

  dragOver(event) {
    if (!this.dragged) return
    event.preventDefault()
    const tile = event.target.closest("[data-arrange-target=tile]")
    if (!tile || tile === this.dragged) return
    const box = tile.getBoundingClientRect()
    const after = event.clientX - box.left > box.width / 2
    tile.parentNode.insertBefore(this.dragged, after ? tile.nextSibling : tile)
  }

  drop(event) {
    event.preventDefault()
  }

  dragEnd() {
    if (!this.dragged) return
    this.dragged.classList.remove("opacity-40")
    this.dragged.draggable = false
    this.dragged = null
    this.save()
  }

  // Resizing
  resizeStart(event) {
    event.preventDefault()
    event.stopPropagation()
    const tile = event.currentTarget.closest("[data-arrange-target=tile]")
    const style = getComputedStyle(this.element)
    const gap = parseFloat(style.columnGap) || 0
    const cellWidth = (this.element.clientWidth - gap * (this.columnsValue - 1)) / this.columnsValue
    // the row height of a one-cell-tall tile (rows grow to fit their content)
    const box0 = tile.getBoundingClientRect()
    const cellHeight = (box0.height - gap * ((parseInt(tile.dataset.h) || 1) - 1)) / (parseInt(tile.dataset.h) || 1)
    const box = tile.getBoundingClientRect()

    const move = moveEvent => {
      const width = this.clamp(Math.round((moveEvent.clientX - box.left + gap) / (cellWidth + gap)), this.columnsValue)
      const height = this.clamp(Math.round((moveEvent.clientY - box.top + gap) / (cellHeight + gap)), this.maxHeightValue)
      this.setSize(tile, width, height)
    }
    const up = () => {
      window.removeEventListener("pointermove", move)
      window.removeEventListener("pointerup", up)
      this.save()
    }
    window.addEventListener("pointermove", move)
    window.addEventListener("pointerup", up)
  }

  setSize(tile, width, height) {
    tile.dataset.w = width
    tile.dataset.h = height
    tile.style.gridColumn = `span ${width}`
    tile.style.gridRow = `span ${height}`
  }

  clamp(value, max) {
    return Math.min(Math.max(value, 1), max)
  }

  save() {
    const tiles = this.tileTargets.map(tile => ({ radio_id: tile.dataset.radioId, w: tile.dataset.w || 1, h: tile.dataset.h || 1 }))
    fetch(this.urlValue, {
      method: "PATCH",
      headers: { "Content-Type": "application/json", "X-CSRF-Token": document.querySelector("meta[name=csrf-token]")?.content },
      body: JSON.stringify({ tiles })
    })
  }
}

import { Controller } from "@hotwired/stimulus"

// The dispatch board: drag a tile by its header and drop it in any cell
// (another radio's side swaps them; its middle links them). The places are
// grid cells, saved on every change.
export default class extends Controller {
  static targets = [ "tile" ]
  static values = { url: String, columns: Number }

  // Moving
  arm(event) {
    if (event.target.closest("button, a, input, select")) return
    event.currentTarget.closest("[data-arrange-target=tile]").draggable = true
  }

  dragStart(event) {
    this.dragged = event.target.closest("[data-arrange-target=tile]")
    if (!this.dragged) return
    event.dataTransfer.effectAllowed = "move"
    event.dataTransfer.setData("text/plain", this.dragged.dataset.radioId)
    // every tile gets its current cell, so that moving one leaves the others in place
    this.freeze()
    this.origin = this.cellOf(this.dragged)
    requestAnimationFrame(() => this.dragged?.classList.add("opacity-40"))
  }

  dragOver(event) {
    if (!this.dragged) return
    event.preventDefault()
    const tile = event.target.closest("[data-arrange-target=tile]")
    if (tile && tile !== this.dragged) {
      const box = tile.getBoundingClientRect()
      const middle = Math.abs(event.clientX - (box.left + box.width / 2)) < box.width / 4 &&
        Math.abs(event.clientY - (box.top + box.height / 2)) < box.height / 4
      if (middle && this.dragged.classList.contains("can-link")) return this.setLinkTarget(tile)
      this.setLinkTarget(null)
      return this.swap(tile)
    }
    if (tile === this.dragged) return this.setLinkTarget(null)
    this.setLinkTarget(null)
    this.moveTo(this.cellAt(event.clientX, event.clientY))
  }

  drop(event) {
    event.preventDefault()
    if (this.linkTarget) {
      this.place(this.dragged, this.origin)
      this.link(this.dragged, this.linkTarget)
    }
  }

  dragEnd() {
    if (!this.dragged) return
    this.dragged.classList.remove("opacity-40")
    this.dragged.draggable = false
    this.dragged = null
    this.setLinkTarget(null)
    if (this.moved) this.save()
    this.moved = false
  }

  // The dragged tile takes the other one's cell, and the other one its own
  swap(tile) {
    const theirs = this.cellOf(tile)
    const mine = this.cellOf(this.dragged)
    if (theirs.x === mine.x && theirs.y === mine.y) return
    this.place(tile, mine)
    this.place(this.dragged, theirs)
    this.moved = true
  }

  moveTo(cell) {
    const mine = this.cellOf(this.dragged)
    if (cell.x === mine.x && cell.y === mine.y) return
    if (this.occupied(cell, this.dragged)) return
    this.place(this.dragged, cell)
    this.moved = true
  }

  // Is the cell taken by another tile?
  occupied(cell, except) {
    return this.tileTargets.some(tile => {
      if (tile === except) return false
      const other = this.cellOf(tile)
      return other.x === cell.x && other.y === cell.y
    })
  }

  freeze() {
    const cells = this.tileTargets.map(tile => [ tile, this.measuredCell(tile) ])
    cells.forEach(([ tile, cell ]) => this.place(tile, cell))
  }

  place(tile, cell) {
    tile.dataset.x = cell.x
    tile.dataset.y = cell.y
    tile.style.setProperty("--x", cell.x)
    tile.style.setProperty("--y", cell.y)
  }

  cellOf(tile) {
    return tile.dataset.x ? { x: parseInt(tile.dataset.x), y: parseInt(tile.dataset.y) } : this.measuredCell(tile)
  }

  // The cell where a tile is now, from its position on the screen
  measuredCell(tile) {
    const grid = this.metrics()
    const box = tile.getBoundingClientRect()
    return {
      x: Math.round((box.left - grid.left) / (grid.cellWidth + grid.gap)) + 1,
      y: Math.round((box.top - grid.top) / (grid.cellHeight + grid.gap)) + 1
    }
  }

  cellAt(clientX, clientY) {
    const grid = this.metrics()
    return {
      x: Math.min(Math.max(Math.floor((clientX - grid.left) / (grid.cellWidth + grid.gap)) + 1, 1), this.columnsValue),
      y: Math.max(Math.floor((clientY - grid.top) / (grid.cellHeight + grid.gap)) + 1, 1)
    }
  }

  // Grid geometry: content origin (scrolled), cell sizes and gap
  metrics() {
    const style = getComputedStyle(this.element)
    const box = this.element.getBoundingClientRect()
    const gap = parseFloat(style.columnGap) || 0
    const left = box.left + parseFloat(style.paddingLeft || 0) - this.element.scrollLeft
    const top = box.top + parseFloat(style.paddingTop || 0) - this.element.scrollTop
    const cellWidth = (this.element.clientWidth - gap * (this.columnsValue - 1)) / this.columnsValue
    return { left, top, gap, cellWidth, cellHeight: this.rowHeight() }
  }

  // The height of one grid row, measured on a tile (rows grow to fit their
  // content, so it isn't a fixed fraction of the board)
  rowHeight() {
    return this.tileTargets[0]?.getBoundingClientRect().height || 200
  }

  setLinkTarget(tile) {
    if (this.linkTarget === tile) return
    this.linkTarget?.removeAttribute("data-link-drop")
    this.linkTarget = tile
    tile?.setAttribute("data-link-drop", "")
  }

  // The new link shows up (line between the tiles) when app_rpt reports it
  link(tile, other) {
    fetch(tile.dataset.linkUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json", "Accept": "application/json",
        "X-CSRF-Token": document.querySelector("meta[name=csrf-token]")?.content },
      body: JSON.stringify({ other_radio_id: other.dataset.radioId, mode: "transceive" })
    })
  }

  save() {
    const tiles = this.tileTargets.map(tile => {
      const cell = tile.dataset.x ? { x: tile.dataset.x, y: tile.dataset.y } : {}
      return { radio_id: tile.dataset.radioId, ...cell }
    })
    fetch(this.urlValue, {
      method: "PATCH",
      headers: { "Content-Type": "application/json", "X-CSRF-Token": document.querySelector("meta[name=csrf-token]")?.content },
      body: JSON.stringify({ tiles })
    })
  }
}

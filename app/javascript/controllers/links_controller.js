import { Controller } from "@hotwired/stimulus"

// Linked radios are joined on screen: a flowing line between their tiles
// (dashed for monitor links) with a chain button in the middle that unlinks
// them. The links come from each tile's live state (data-links), so the lines
// follow the AMI LINKS events.
export default class extends Controller {
  connect() {
    this.layer = document.createElement("div")
    this.layer.className = "pointer-events-none absolute left-0 top-0 z-10"
    this.layer.setAttribute("aria-hidden", "false")
    this.svg = document.createElementNS("http://www.w3.org/2000/svg", "svg")
    this.svg.setAttribute("class", "absolute left-0 top-0 overflow-visible")
    this.layer.append(this.svg)
    this.element.append(this.layer)
    this.pairs = new Map()

    this.redraw = this.redraw.bind(this)
    this.observer = new MutationObserver(() => this.schedule())
    this.observer.observe(this.element, { subtree: true, childList: true, attributes: true, attributeFilter: [ "data-links", "style" ] })
    this.resizeObserver = new ResizeObserver(() => this.schedule())
    this.resizeObserver.observe(this.element)
    window.addEventListener("resize", this.redraw)
    this.schedule()
  }

  disconnect() {
    this.observer.disconnect()
    this.resizeObserver.disconnect()
    window.removeEventListener("resize", this.redraw)
    this.layer.remove()
  }

  schedule() {
    cancelAnimationFrame(this.frame)
    this.frame = requestAnimationFrame(this.redraw)
  }

  // Pairs of tiles on screen that are linked: "nodeA|nodeB" => { a, b, monitor }
  linkedPairs() {
    const tiles = [ ...this.element.querySelectorAll("[data-arrange-target=tile]") ]
    const byNode = new Map(tiles.map(tile => [ tile.dataset.node, tile ]))
    const pairs = new Map()
    tiles.forEach(tile => {
      const state = tile.querySelector("[data-links-target=state]")
      let links = []
      try { links = JSON.parse(state?.dataset.links || "[]") } catch {}
      links.forEach(link => {
        const other = byNode.get(link.node)
        if (!other || other === tile) return
        const key = [ tile.dataset.node, link.node ].sort().join("|")
        const pair = pairs.get(key) || { a: tile, b: other, monitor: false }
        pair.monitor = pair.monitor || link.mode === "monitor"
        pairs.set(key, pair)
      })
    })
    return pairs
  }

  redraw() {
    const pairs = this.linkedPairs()
    this.layer.style.width = `${this.element.scrollWidth}px`
    this.layer.style.height = `${this.element.scrollHeight}px`
    this.svg.setAttribute("width", this.element.scrollWidth)
    this.svg.setAttribute("height", this.element.scrollHeight)

    // the tiles that are linked get the link's frame
    const linked = new Set([ ...pairs.values() ].flatMap(pair => [ pair.a, pair.b ]))
    this.element.querySelectorAll("[data-arrange-target=tile]").forEach(tile => tile.toggleAttribute("data-linked", linked.has(tile)))

    // links that went away: the line breaks
    for (const [ key, drawn ] of this.pairs) {
      if (!pairs.has(key)) {
        this.pairs.delete(key)
        this.breakLine(drawn)
      }
    }
    for (const [ key, pair ] of pairs) {
      let drawn = this.pairs.get(key)
      if (!drawn) {
        drawn = this.createLine(pair)
        this.pairs.set(key, drawn)
      }
      this.place(drawn, pair)
    }
  }

  createLine(pair) {
    const path = document.createElementNS("http://www.w3.org/2000/svg", "path")
    path.setAttribute("class", `link-line ${pair.monitor ? "link-line-monitor" : ""} link-line-new`)
    this.svg.append(path)

    const button = document.createElement("button")
    button.type = "button"
    button.className = "link-chain pointer-events-auto"
    const names = { a: pair.a.dataset.name, b: pair.b.dataset.name }
    button.title = this.text("unlinkPair", names)
    button.setAttribute("aria-label", button.title)
    button.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" class="size-4"><path d="M10 14a4 4 0 0 0 5.7 0l3-3a4 4 0 0 0-5.7-5.7l-1 1"/><path d="M14 10a4 4 0 0 0-5.7 0l-3 3a4 4 0 0 0 5.7 5.7l1-1"/></svg>'
    // only who may link radios gets the button working
    if (!pair.a.classList.contains("can-link")) button.disabled = true
    button.addEventListener("click", () => this.unlink(pair, drawn))
    this.layer.append(button)
    const drawn = { path, button, pair }
    return drawn
  }

  place(drawn, pair) {
    const origin = this.element.getBoundingClientRect()
    const offset = { x: this.element.scrollLeft - origin.left, y: this.element.scrollTop - origin.top }
    const a = pair.a.getBoundingClientRect()
    const b = pair.b.getBoundingClientRect()
    const [ start, end ] = this.edgePoints(a, b)
    const x1 = start.x + offset.x, y1 = start.y + offset.y
    const x2 = end.x + offset.x, y2 = end.y + offset.y
    drawn.path.setAttribute("d", `M ${x1} ${y1} L ${x2} ${y2}`)
    drawn.path.style.setProperty("--length", Math.hypot(x2 - x1, y2 - y1))
    drawn.button.style.left = `${(x1 + x2) / 2}px`
    drawn.button.style.top = `${(y1 + y2) / 2}px`
    drawn.pair = pair
  }

  // Neighbours: a seam along the side they share, in the gap between them.
  // Tiles further apart: a line from one's facing side to the other's.
  edgePoints(a, b) {
    const ca = { x: a.left + a.width / 2, y: a.top + a.height / 2 }
    const cb = { x: b.left + b.width / 2, y: b.top + b.height / 2 }
    const horizontal = Math.abs(cb.x - ca.x) / (a.width + b.width) >= Math.abs(cb.y - ca.y) / (a.height + b.height)
    const inset = 18
    if (horizontal) {
      const [ left, right ] = cb.x > ca.x ? [ a, b ] : [ b, a ]
      const top = Math.max(a.top, b.top), bottom = Math.min(a.bottom, b.bottom)
      if (right.left - left.right < 40 && bottom - top > 2 * inset) {
        const x = (left.right + right.left) / 2
        return [ { x, y: top + inset }, { x, y: bottom - inset } ]
      }
      const dir = cb.x > ca.x ? 1 : -1
      return [ { x: ca.x + dir * a.width / 2, y: ca.y }, { x: cb.x - dir * b.width / 2, y: cb.y } ]
    }
    const [ upper, lower ] = cb.y > ca.y ? [ a, b ] : [ b, a ]
    const left = Math.max(a.left, b.left), right = Math.min(a.right, b.right)
    if (lower.top - upper.bottom < 40 && right - left > 2 * inset) {
      const y = (upper.bottom + lower.top) / 2
      return [ { x: left + inset, y }, { x: right - inset, y } ]
    }
    const dir = cb.y > ca.y ? 1 : -1
    return [ { x: ca.x, y: ca.y + dir * a.height / 2 }, { x: cb.x, y: cb.y - dir * b.height / 2 } ]
  }

  async unlink(pair, drawn) {
    const names = { a: pair.a.dataset.name, b: pair.b.dataset.name }
    if (!confirm(this.text("unlinkPairConfirm", names))) return
    drawn.button.disabled = true
    drawn.path.classList.add("link-line-breaking")
    const response = await fetch(`${pair.a.dataset.unlinkUrl}/${pair.b.dataset.node}`, {
      method: "DELETE",
      headers: { "Accept": "application/json", "X-CSRF-Token": document.querySelector("meta[name=csrf-token]")?.content }
    }).catch(() => null)
    if (!response?.ok) {
      drawn.path.classList.remove("link-line-breaking")
      drawn.button.disabled = false
    }
    // the line goes away when app_rpt reports the new links
  }

  breakLine(drawn) {
    drawn.button.remove()
    drawn.path.classList.add("link-line-broken")
    setTimeout(() => drawn.path.remove(), 700)
  }

  text(key, values) {
    const strings = JSON.parse(document.getElementById("dispatch-strings").textContent)
    return strings[key].replace("{a}", values.a).replace("{b}", values.b)
  }
}

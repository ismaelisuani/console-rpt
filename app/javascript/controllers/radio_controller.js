import { Controller } from "@hotwired/stimulus"
import { RadioCall } from "lib/radio_audio"

// One radio tile: focus (a click or the arrows), whether it goes in the
// group PTT, volume and mute (kept per radio in this browser), the
// console's WebRTC call to the radio and PTT.
export default class extends Controller {
  static targets = [ "volume", "volumeLabel", "muteButton", "speakerIcon", "mutedIcon", "connectButton",
    "connectionBadge", "ptt", "linkDialog", "audio", "problem", "groupButton" ]
  static values = { id: Number, callUrl: String, pttUrl: String }

  disconnect() {
    this.call?.stop()
  }

  connect() {
    const saved = this.load()
    this.volumeTarget.value = saved.volume ?? 70
    this.muted = saved.muted ?? false
    this.connected = false
    this.renderVolume()
  }

  // Selection
  // A click anywhere on the tile (but its controls) focuses it
  focus(event) {
    if (event.target.closest("button, input, select, a, dialog, label")) return
    this.element.focus({ preventScroll: true })
  }

  toggleGroup() {
    this.setGroup(!this.selected)
  }

  setGroup(included) {
    this.element.toggleAttribute("data-selected", included)
    this.groupButtonTarget.setAttribute("aria-pressed", included)
    this.dispatch("group", { bubbles: true })
  }

  get selected() {
    return this.element.hasAttribute("data-selected")
  }

  get name() {
    return this.element.dataset.name
  }


  // Volume
  setVolume() {
    this.muted = false
    this.save()
    this.renderVolume()
  }

  toggleMute() {
    this.muted = !this.muted
    this.save()
    this.renderVolume()
  }

  mute() {
    this.muted = true
    this.save()
    this.renderVolume()
  }

  renderVolume() {
    this.volumeLabelTarget.textContent = this.muted ? this.t("muted") : `${this.volumeTarget.value}%`
    this.speakerIconTarget.hidden = this.muted
    this.mutedIconTarget.hidden = !this.muted
    this.muteButtonTarget.classList.toggle("border-tx-strong", this.muted)
    this.muteButtonTarget.classList.toggle("text-tx-ink", this.muted)
    this.volumeTarget.classList.toggle("opacity-40", this.muted)
    this.call?.setVolume(this.volumeTarget.value / 100, this.muted)
  }

  // Console connection
  toggleConnection() {
    this.connected ? this.disconnectRadio() : this.connectRadio()
  }

  async connectRadio() {
    if (this.connectButtonTarget.disabled || this.call) return
    this.setStatus("connecting")
    this.hideProblem()
    const call = new RadioCall(this.audioTarget, { onEnded: () => this.callEnded(call) })
    this.call = call
    let config
    try {
      const response = await fetch(this.callUrlValue, { method: "POST", headers: this.headers })
      if (!response.ok) throw new Error(`http ${response.status}`)
      config = await response.json()
      await call.start(config)
      if (this.call !== call) return call.stop()
      call.setVolume(this.volumeTarget.value / 100, this.muted)
      this.connected = true
      this.renderConnection()
    } catch (error) {
      if (this.call === call) this.call = null
      call.stop()
      this.connected = false
      this.renderConnection()
      this.showProblem(error.message, config)
    }
  }

  // Why the call didn't connect, in the tile
  showProblem(reason, config) {
    if (reason === "microphone") {
      this.setStatus("microphoneDenied", "text-tx-ink")
      this.problem(this.t("microphoneHint"))
    } else if (reason === "websocket" && config) {
      this.setStatus("audioUnreachable", "text-tx-ink")
      // A self-signed certificate (tests) has to be accepted once in the browser
      const url = config.ws.replace(/^ws/, "http")
      this.problem(this.t("certificateHint"), url, this.t("openServer"))
    } else {
      this.setStatus("callFailed", "text-tx-ink")
    }
  }

  problem(text, url, linkText) {
    const element = this.problemTarget
    element.textContent = text + (url ? " " : "")
    if (url) {
      const link = document.createElement("a")
      link.href = url
      link.target = "_blank"
      link.rel = "noopener"
      link.className = "underline hover:text-ink-strong"
      link.textContent = linkText
      element.append(link)
    }
    element.hidden = false
  }

  hideProblem() {
    this.problemTarget.hidden = true
  }

  disconnectRadio() {
    this.pttUp()
    const call = this.call
    this.call = null
    call?.stop()
    this.connected = false
    this.renderConnection()
  }

  callEnded(call) {
    if (this.call !== call) return
    this.call = null
    this.pttUp()
    const wasConnected = this.connected
    this.connected = false
    this.renderConnection()
    if (wasConnected) this.setStatus("callEnded", "text-warn-ink")
  }

  setStatus(key, color) {
    this.connectionBadgeTarget.textContent = this.t(key)
    this.connectionBadgeTarget.classList.remove("text-tx-ink", "text-warn-ink")
    if (color) this.connectionBadgeTarget.classList.add(color)
  }

  renderConnection() {
    const button = this.connectButtonTarget
    button.lastChild.textContent = ` ${this.connected ? button.dataset.disconnectLabel : button.dataset.connectLabel}`
    button.title = (this.connected ? button.dataset.disconnectTitle : button.dataset.connectTitle) || ""
    button.setAttribute("aria-pressed", this.connected)
    button.classList.toggle("border-accent", this.connected)
    button.classList.toggle("bg-accent-soft", this.connected)
    button.classList.toggle("text-accent-ink", this.connected)
    this.setStatus(this.connected ? "connected" : "disconnected")
    this.dispatch("group", { bubbles: true })
    if (this.hasPttTarget) {
      this.pttTarget.disabled = !this.connected
      this.pttTarget.title = this.connected ? this.t("pttHint") : this.t("connectFirst")
    }
  }

  // PTT
  pttDown(event) {
    if (!this.hasPttTarget || this.pttTarget.disabled) return
    event?.preventDefault()
    if (event?.pointerId !== undefined) this.pttTarget.setPointerCapture?.(event.pointerId)
    this.pttTarget.toggleAttribute("data-pressed", true)
    // the tile shows it at once; app_rpt confirms it a moment later
    this.element.toggleAttribute("data-console-ptt", true)
    this.call?.ptt(true)
    fetch(this.pttUrlValue, { method: "POST", headers: this.headers }).catch(() => {})
  }

  pttUp() {
    if (!this.hasPttTarget || !this.pttTarget.hasAttribute("data-pressed")) return
    this.pttTarget.removeAttribute("data-pressed")
    this.element.removeAttribute("data-console-ptt")
    this.call?.ptt(false)
  }

  // Link dialog
  openLink() {
    this.linkDialogTarget.showModal()
  }

  closeLink() {
    this.linkDialogTarget.close()
  }

  // Helpers
  get headers() {
    return { "X-CSRF-Token": document.querySelector("meta[name=csrf-token]")?.content, "Accept": "application/json" }
  }

  t(key) {
    return JSON.parse(document.getElementById("dispatch-strings").textContent)[key]
  }

  load() {
    try { return JSON.parse(localStorage.getItem(this.storageKey)) || {} } catch { return {} }
  }

  save() {
    try { localStorage.setItem(this.storageKey, JSON.stringify({ volume: this.volumeTarget.value, muted: this.muted })) } catch {}
  }

  get storageKey() {
    return `radio-${this.idValue}-audio`
  }
}

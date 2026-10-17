import { Controller } from "@hotwired/stimulus"
import { RadioCall } from "lib/radio_audio"

// One radio tile: selection (space bar PTT), volume and mute (kept per radio
// in this browser), the console's WebRTC call to the radio and PTT.
export default class extends Controller {
  static targets = [ "volume", "volumeLabel", "muteButton", "speakerIcon", "mutedIcon", "connectButton",
    "connectionBadge", "ptt", "pttHint", "linkDialog", "audio" ]
  static values = { id: Number, node: String, callUrl: String, pttUrl: String, canTransmit: Boolean }

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
  select(event) {
    if (event.target.closest("button, input, select, a, dialog")) return
    this.element.toggleAttribute("data-selected")
  }

  get selected() {
    return this.element.hasAttribute("data-selected")
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
    const call = new RadioCall(this.audioTarget, { onEnded: () => this.callEnded(call) })
    this.call = call
    try {
      const response = await fetch(this.callUrlValue, { method: "POST", headers: this.headers })
      if (!response.ok) throw new Error(`http ${response.status}`)
      await call.start(await response.json())
      if (this.call !== call) return call.stop()
      call.setVolume(this.volumeTarget.value / 100, this.muted)
      this.connected = true
      this.renderConnection()
    } catch (error) {
      if (this.call === call) this.call = null
      call.stop()
      this.connected = false
      this.renderConnection()
      this.setStatus(error.message === "microphone" ? "microphoneDenied" : "callFailed", "text-tx-ink")
    }
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
    button.textContent = this.connected ? button.dataset.disconnectLabel : button.dataset.connectLabel
    button.classList.toggle("border-accent", this.connected)
    button.classList.toggle("bg-accent-soft", this.connected)
    button.classList.toggle("text-accent-ink", this.connected)
    this.setStatus(this.connected ? "connected" : "disconnected")
    if (this.hasPttTarget) {
      this.pttTarget.disabled = !this.connected
      this.pttHintTarget.textContent = this.t(this.connected ? "pttHold" : "connectFirst")
    }
  }

  // PTT
  pttDown(event) {
    if (!this.hasPttTarget || this.pttTarget.disabled) return
    event?.preventDefault()
    this.pttTarget.setPointerCapture?.(event.pointerId)
    this.pttTarget.toggleAttribute("data-pressed", true)
    this.call?.ptt(true)
    fetch(this.pttUrlValue, { method: "POST", headers: this.headers }).catch(() => {})
  }

  pttUp() {
    if (!this.hasPttTarget || !this.pttTarget.hasAttribute("data-pressed")) return
    this.pttTarget.removeAttribute("data-pressed")
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

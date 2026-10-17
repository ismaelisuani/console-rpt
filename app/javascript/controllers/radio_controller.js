import { Controller } from "@hotwired/stimulus"

// One radio tile: selection (space bar PTT), volume and mute (kept per radio
// in this browser), console connection and PTT. The audio itself (WebRTC to
// the radio's server) plugs in through connect()/disconnect()/setPtt().
export default class extends Controller {
  static targets = [ "volume", "volumeLabel", "muteButton", "speakerIcon", "mutedIcon", "connectButton",
    "connectionBadge", "ptt", "pttHint", "linkDialog" ]
  static values = { id: Number, node: String, webrtc: String, canTransmit: Boolean }

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
    this.dispatch("volume", { detail: { volume: this.muted ? 0 : this.volumeTarget.value / 100 } })
  }

  // Console connection
  toggleConnection() {
    this.connected ? this.disconnectRadio() : this.connectRadio()
  }

  connectRadio() {
    if (this.connectButtonTarget.disabled) return
    this.connected = true
    this.renderConnection()
    this.dispatch("connect")
  }

  disconnectRadio() {
    this.connected = false
    this.pttUp()
    this.renderConnection()
    this.dispatch("disconnect")
  }

  renderConnection() {
    const button = this.connectButtonTarget
    button.textContent = this.connected ? button.dataset.disconnectLabel : button.dataset.connectLabel
    button.classList.toggle("border-accent", this.connected)
    button.classList.toggle("bg-accent-soft", this.connected)
    button.classList.toggle("text-accent-ink", this.connected)
    this.connectionBadgeTarget.textContent = this.t(this.connected ? "connected" : "disconnected")
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
    this.dispatch("ptt", { detail: { pressed: true } })
  }

  pttUp() {
    if (!this.hasPttTarget || !this.pttTarget.hasAttribute("data-pressed")) return
    this.pttTarget.removeAttribute("data-pressed")
    this.dispatch("ptt", { detail: { pressed: false } })
  }

  // Link dialog
  openLink() {
    this.linkDialogTarget.showModal()
  }

  closeLink() {
    this.linkDialogTarget.close()
  }

  // Helpers
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

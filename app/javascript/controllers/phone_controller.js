import { Controller } from "@hotwired/stimulus"
import { RadioCall } from "lib/radio_audio"

// The console's phone: dial with the keypad (or type), call through the
// server's [console-phone-out], hang up, mute the microphone; keypad digits
// during a call go as DTMF. The last numbers are kept in this browser.
export default class extends Controller {
  static targets = [ "number", "status", "callState", "callButton", "hangupButton", "muteButton", "audio", "recent" ]
  static values = { url: String, available: Boolean }

  connect() {
    this.renderRecent()
    this.render()
  }

  disconnect() {
    this.call?.stop()
  }

  press(event) {
    const key = event.currentTarget.dataset.key
    if (this.call) return this.call.sendDigit(key)
    this.numberTarget.value += key
    this.render()
  }

  typed(event) {
    if (event.key === "Enter") this.dial()
    this.render()
  }

  async dial() {
    const number = this.numberTarget.value.replace(/[\s-]/g, "")
    if (!number || this.call || !this.availableValue) return
    this.setState(this.t("calling"))
    const call = new RadioCall(this.audioTarget, { talk: "open", onEnded: () => this.ended(call) })
    this.call = call
    this.render()
    try {
      const response = await fetch(this.urlValue, {
        method: "POST",
        headers: { "Content-Type": "application/json", "Accept": "application/json",
          "X-CSRF-Token": document.querySelector("meta[name=csrf-token]")?.content },
        body: JSON.stringify({ number })
      })
      if (!response.ok) throw new Error(`http ${response.status}`)
      await call.start(await response.json())
      this.remember(number)
      this.startedAt = Date.now()
      this.timer = setInterval(() => this.tick(), 1000)
      this.tick()
    } catch (error) {
      if (this.call === call) this.call = null
      call.stop()
      this.setState(this.t(error.message === "microphone" ? "microphoneDenied" : "failed"))
      this.render()
    }
  }

  hangup() {
    this.call?.stop()
  }

  ended(call) {
    if (this.call !== call) return
    this.call = null
    this.muted = false
    clearInterval(this.timer)
    this.setState(this.t("ended"))
    this.render()
  }

  toggleMute() {
    if (!this.call) return
    this.muted = !this.muted
    this.call.setMicrophone(!this.muted)
    this.render()
  }

  redial(event) {
    this.numberTarget.value = event.currentTarget.dataset.number
    this.dial()
  }

  tick() {
    const seconds = Math.floor((Date.now() - this.startedAt) / 1000)
    this.setState(`${this.t("inCall")} · ${String(Math.floor(seconds / 60)).padStart(2, "0")}:${String(seconds % 60).padStart(2, "0")}`)
  }

  render() {
    const inCall = !!this.call
    this.callButtonTarget.disabled = inCall || !this.availableValue || !this.numberTarget.value.trim()
    this.hangupButtonTarget.disabled = !inCall
    this.muteButtonTarget.disabled = !inCall
    this.muteButtonTarget.setAttribute("aria-pressed", !!this.muted)
    this.numberTarget.readOnly = inCall
    this.statusTarget.textContent = this.t(this.availableValue ? "ready" : "unavailable")
  }

  setState(text) {
    this.callStateTarget.textContent = text
  }

  // Recent numbers
  remember(number) {
    const recent = [ { number, at: Date.now() }, ...this.recent.filter(entry => entry.number !== number) ].slice(0, 5)
    try { localStorage.setItem("phone-recent", JSON.stringify(recent)) } catch {}
    this.renderRecent()
  }

  get recent() {
    try { return JSON.parse(localStorage.getItem("phone-recent")) || [] } catch { return [] }
  }

  renderRecent() {
    const format = new Intl.DateTimeFormat(document.documentElement.lang, { hour: "2-digit", minute: "2-digit" })
    this.recentTarget.replaceChildren(...this.recent.map(entry => {
      const button = document.createElement("button")
      button.type = "button"
      button.className = "flex w-full justify-between rounded-md px-1.5 py-0.5 text-left hover:bg-raised"
      button.dataset.number = entry.number
      button.dataset.action = "phone#redial"
      button.innerHTML = `<span class="text-ink"></span><span class="text-faint"></span>`
      button.children[0].textContent = `↗ ${entry.number}`
      button.children[1].textContent = format.format(new Date(entry.at))
      return button
    }))
  }

  t(key) {
    return JSON.parse(document.getElementById("phone-strings").textContent)[key]
  }
}

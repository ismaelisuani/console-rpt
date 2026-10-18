import { Controller } from "@hotwired/stimulus"
import { startPhone } from "lib/phone_agent"

// The console's phone: the user's own extension, registered when the page
// opens (green when registered, red when not). Dial with the keypad, type,
// a favorite or a recent number; answer or reject incoming calls (with a
// ring); mute; keypad digits during a call go as DTMF.
export default class extends Controller {
  static targets = [ "number", "status", "statusDot", "identity", "callState", "callButton", "hangupButton",
    "muteButton", "audio", "recent", "incoming", "incomingFrom" ]
  static values = { accountUrl: String, available: Boolean }

  async connect() {
    this.renderRecent()
    this.render()
    if (!this.availableValue) return this.setStatus("unavailable")
    try {
      const response = await fetch(this.accountUrlValue, { headers: { "Accept": "application/json" } })
      if (!response.ok) throw new Error(`http ${response.status}`)
      const account = await response.json()
      this.identityTarget.textContent = `${this.t("extension")} ${account.extension} · ${account.name}`
      this.setStatus("connecting")
      this.agent = startPhone(account, {
        onStatus: status => this.setStatus(status),
        onIncoming: from => this.incomingCall(from),
        onCallState: state => this.callStateChanged(state)
      })
    } catch {
      this.setStatus("unavailable")
    }
  }

  disconnect() {
    this.stopRing()
    this.agent?.stop()
  }

  // Keypad and number
  press(event) {
    const key = event.currentTarget.dataset.key
    if (this.inCall) return this.agent.sendDigit(key)
    this.numberTarget.value += key
    this.render()
  }

  typed(event) {
    if (event.key === "Enter") this.dial()
    this.render()
  }

  dial() {
    const number = this.numberTarget.value.replace(/[\s-]/g, "")
    if (!number || this.inCall || !this.registered) return
    this.inCall = true
    this.number = number
    this.setState(this.t("calling"))
    this.agent.call(number, this.audioTarget)
    this.render()
  }

  callNumber(event) {
    this.numberTarget.value = event.currentTarget.dataset.number
    this.dial()
  }

  hangup() {
    this.agent?.hangup()
  }

  toggleMute() {
    if (!this.inCall) return
    this.muted = !this.muted
    this.agent.setMuted(this.muted)
    this.render()
  }

  // Incoming calls
  incomingCall(from) {
    this.inCall = true
    this.ringing = true
    this.incomingFromTarget.textContent = from
    this.incomingTarget.hidden = false
    this.setState(`${this.t("incoming")} · ${from}`)
    this.startRing()
    this.render()
  }

  answer() {
    this.stopRing()
    this.ringing = false
    this.incomingTarget.hidden = true
    this.agent.answer(this.audioTarget)
  }

  reject() {
    this.stopRing()
    this.agent.hangup()
  }

  callStateChanged(state) {
    // "ringing": our outgoing call rings at the other end (an incoming one
    // rings here: its own progress event changes nothing)
    if (state === "ringing") {
      if (!this.ringing) this.setState(this.t("ringing"))
      return
    }
    if (state === "confirmed") {
      if (this.number) this.remember(this.number)
      this.startedAt = Date.now()
      clearInterval(this.timer)
      this.timer = setInterval(() => this.tick(), 1000)
      this.tick()
      return this.render()
    }
    // ended, failed or microphone
    this.stopRing()
    clearInterval(this.timer)
    this.inCall = this.ringing = this.muted = false
    this.number = null
    this.incomingTarget.hidden = true
    this.setState(this.t({ ended: "ended", failed: "failed", microphone: "microphoneDenied" }[state] || "ended"))
    this.render()
  }

  tick() {
    const seconds = Math.floor((Date.now() - this.startedAt) / 1000)
    this.setState(`${this.t("inCall")} · ${String(Math.floor(seconds / 60)).padStart(2, "0")}:${String(seconds % 60).padStart(2, "0")}`)
  }

  // A two-tone ring while a call comes in (Web Audio, no file)
  startRing() {
    try {
      this.ringContext = new AudioContext()
      const ring = () => {
        const now = this.ringContext.currentTime
        ;[ 0, 0.4 ].forEach(offset => {
          const tone = this.ringContext.createOscillator()
          const gain = this.ringContext.createGain()
          tone.frequency.value = 440
          gain.gain.value = 0.15
          tone.connect(gain).connect(this.ringContext.destination)
          tone.start(now + offset)
          tone.stop(now + offset + 0.3)
        })
      }
      ring()
      this.ringTimer = setInterval(ring, 3000)
    } catch {}
  }

  stopRing() {
    clearInterval(this.ringTimer)
    this.ringContext?.close().catch(() => {})
    this.ringContext = null
  }

  // Status and buttons
  setStatus(status) {
    this.registered = status === "registered"
    const colors = { registered: "bg-rx", connecting: "bg-warn-ink" }
    this.statusDotTarget.className = `size-2 shrink-0 rounded-full ${colors[status] || "bg-tx"}`
    this.statusTarget.textContent = this.t(status === "failed" ? "registrationFailed" : status)
    this.render()
  }

  render() {
    this.callButtonTarget.disabled = this.inCall || !this.registered || !this.numberTarget.value.trim()
    this.hangupButtonTarget.disabled = !this.inCall
    this.muteButtonTarget.disabled = !this.inCall || this.ringing
    this.muteButtonTarget.setAttribute("aria-pressed", !!this.muted)
    this.numberTarget.readOnly = !!this.inCall
  }

  setState(text) {
    this.callStateTarget.textContent = text
  }

  // Recent numbers (this browser)
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
      button.dataset.action = "phone#callNumber"
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

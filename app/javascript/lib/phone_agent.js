import JsSIP from "jssip"

// The console user's own phone: their extension registered on the phone
// server (JsSIP). Outgoing calls, incoming calls, mute and keypad DTMF.
export class PhoneAgent {
  constructor(account, { onStatus, onIncoming, onCallState }) {
    this.account = account
    this.onStatus = onStatus
    this.onIncoming = onIncoming
    this.onCallState = onCallState
    this.ua = new JsSIP.UA({
      sockets: [ new JsSIP.WebSocketInterface(account.ws) ],
      uri: `sip:${account.extension}@${account.host}`,
      password: account.password,
      display_name: account.name,
      register: true,
      session_timers: false,
      user_agent: "console-rpt"
    })
    this.ua.on("registered", () => this.onStatus("registered"))
    this.ua.on("unregistered", () => this.onStatus("unregistered"))
    this.ua.on("registrationFailed", () => this.onStatus("failed"))
    this.ua.on("disconnected", () => this.onStatus("unregistered"))
    this.ua.on("newRTCSession", ({ session, originator }) => {
      if (originator !== "remote") return
      if (this.session) return session.terminate({ status_code: 486 })
      this.track(session)
      this.onIncoming(session.remote_identity.display_name || session.remote_identity.uri.user)
    })
    this.ua.start()
  }

  call(number, audio) {
    this.audio = audio
    this.track(this.ua.call(`sip:${number}@${this.account.host}`, {
      mediaConstraints: { audio: true, video: false },
      pcConfig: { iceServers: [] }
    }))
  }

  answer(audio) {
    this.audio = audio
    this.session?.answer({ mediaConstraints: { audio: true, video: false }, pcConfig: { iceServers: [] } })
  }

  hangup() {
    if (this.session && !this.session.isEnded()) this.session.terminate()
  }

  setMuted(muted) {
    this.session?.connection?.getSenders().forEach(sender => { if (sender.track) sender.track.enabled = !muted })
  }

  sendDigit(digit) {
    if (this.session?.isEstablished()) this.session.sendDTMF(digit, { transportType: JsSIP.C.DTMF_TRANSPORT.RFC2833 })
  }

  stop() {
    this.hangup()
    this.ua.stop()
  }

  track(session) {
    this.session = session
    const attach = () => session.connection?.addEventListener("track", event => {
      if (!this.audio) return
      this.audio.srcObject = event.streams[0]
      this.audio.play().catch(() => {})
    })
    if (session.connection) attach()
    else session.on("peerconnection", attach)
    session.on("progress", () => this.onCallState("ringing"))
    session.on("confirmed", () => this.onCallState("confirmed"))
    session.on("failed", event => this.ended(event.cause === JsSIP.C.causes.USER_DENIED_MEDIA_ACCESS ? "microphone" : "failed"))
    session.on("ended", () => this.ended("ended"))
  }

  ended(reason) {
    this.session = null
    if (this.audio) this.audio.srcObject = null
    this.onCallState(reason)
  }
}

// Leaving the page unregisters the phone (radio_audio.js hangs up the radios)
const agents = new Set()
window.addEventListener("pagehide", () => agents.forEach(agent => agent.stop()))
export function startPhone(account, handlers) {
  const agent = new PhoneAgent(account, handlers)
  agents.add(agent)
  return agent
}

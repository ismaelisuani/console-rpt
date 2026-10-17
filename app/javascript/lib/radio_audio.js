import JsSIP from "jssip"

// WebRTC calls from the console to the radios. One SIP user agent per server
// (WebSocket), no registration; each call carries the token the server's
// dialplan checks. PTT is app_rpt's phone mode: *99 keys up, # unkeys, sent
// as RFC 4733 DTMF; the microphone only goes out while PTT is held.

const agents = new Map()

function agentFor({ ws, host, username, password }) {
  let agent = agents.get(ws)
  if (agent && !agent.failed) return agent

  const ua = new JsSIP.UA({
    sockets: [ new JsSIP.WebSocketInterface(ws) ],
    uri: `sip:${username}@${host}`,
    password,
    register: false,
    session_timers: false,
    user_agent: "console-rpt"
  })
  agent = { ua, failed: false }
  agent.ready = new Promise((resolve, reject) => {
    ua.on("connected", resolve)
    ua.on("disconnected", () => { agent.failed = true; reject(new Error("websocket")) })
  })
  agent.ready.catch(() => {})
  ua.start()
  agents.set(ws, agent)
  return agent
}

export class RadioCall {
  constructor(audio, { onEnded } = {}) {
    this.audio = audio
    this.onEnded = onEnded
    this.pressed = false
  }

  // Resolves when the radio answers; rejects with "websocket", "microphone" or the SIP cause
  async start(config) {
    this.operate = config.level === "operate"
    const agent = agentFor(config)
    await agent.ready

    return new Promise((resolve, reject) => {
      const session = agent.ua.call(config.uri, {
        extraHeaders: [ `X-Console-Token: ${config.token}` ],
        mediaConstraints: { audio: this.operate, video: false },
        rtcOfferConstraints: { offerToReceiveAudio: true, offerToReceiveVideo: false },
        pcConfig: { iceServers: [] }
      })
      this.session = session

      session.connection.addEventListener("track", event => {
        this.audio.srcObject = event.streams[0]
        this.audio.play().catch(() => {})
      })
      session.on("confirmed", () => {
        this.setMicrophone(false)
        resolve()
      })
      session.on("failed", event => {
        const cause = event.cause === JsSIP.C.causes.USER_DENIED_MEDIA_ACCESS ? "microphone" : event.cause
        reject(new Error(cause))
        this.ended(cause)
      })
      session.on("ended", event => this.ended(event.cause))
    })
  }

  ptt(pressed) {
    if (!this.operate || !this.session?.isEstablished() || pressed === this.pressed) return
    this.pressed = pressed
    clearTimeout(this.micTimer)
    if (pressed) {
      this.setMicrophone(true)
      this.dtmf("*99")
    } else {
      this.dtmf("#")
      // the last syllable still goes out
      this.micTimer = setTimeout(() => this.setMicrophone(false), 250)
    }
  }

  stop() {
    if (this.session && !this.session.isEnded()) this.session.terminate()
  }

  setVolume(volume, muted) {
    this.audio.volume = volume
    this.audio.muted = muted
  }

  dtmf(tones) {
    this.session.sendDTMF(tones, { transportType: JsSIP.C.DTMF_TRANSPORT.RFC2833, duration: 100, interToneGap: 70 })
  }

  setMicrophone(enabled) {
    this.session?.connection?.getSenders().forEach(sender => {
      if (sender.track) sender.track.enabled = enabled
    })
  }

  ended(cause) {
    if (this.finished) return
    this.finished = true
    this.audio.srcObject = null
    this.onEnded?.(cause)
  }
}

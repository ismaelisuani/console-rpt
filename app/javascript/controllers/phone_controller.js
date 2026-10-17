import { Controller } from "@hotwired/stimulus"

// SIP phone keypad. Registration and calls come with the WebRTC stage.
export default class extends Controller {
  static targets = [ "number" ]

  press(event) {
    this.numberTarget.value += event.currentTarget.dataset.key
  }
}

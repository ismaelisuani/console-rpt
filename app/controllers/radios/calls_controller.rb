# Starts the console's WebRTC call to a radio (the browser places it)
class Radios::CallsController < ApplicationController
  def create
    radio = Current.user.radios.find(params.expect(:radio_id))
    return head :forbidden unless Current.user.can_listen_to?(radio)
    return head :unprocessable_entity unless radio.server.webrtc?

    render json: ConsoleCall.new(radio, Current.user)
  end
end

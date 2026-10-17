# The console user pressed PTT on a radio
class Radios::PttsController < ApplicationController
  def create
    radio = Current.user.radios.find(params.expect(:radio_id))
    return head :forbidden unless Current.user.can_transmit_on?(radio)

    radio.ptt_pressed_by!(Current.user)
    head :no_content
  end
end

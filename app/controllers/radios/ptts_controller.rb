# The console user pressed PTT on a radio: the transmission that app_rpt
# reports a moment later is named after them
class Radios::PttsController < ApplicationController
  def create
    radio = Current.user.radios.find(params.expect(:radio_id))
    return head :forbidden unless Current.user.can_transmit_on?(radio)

    radio.update_columns(ptt_user_id: Current.user.id, ptt_at: Time.current)
    head :no_content
  end
end

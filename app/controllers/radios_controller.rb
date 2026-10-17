# Link commands from the dispatch screen, sent to app_rpt as DTMF functions
# (*1 disconnect, *2 monitor, *3 transceive, as in the stock rpt.conf)
class RadiosController < ApplicationController
  before_action :set_radio

  def link
    other = Current.user.radios.find(params.expect(:other_radio_id))
    function = params[:mode] == "monitor" ? "*2" : "*3"
    run(function, other.node, t(".sent", radio: @radio.name, other: other.name))
  end

  def unlink
    node = params.expect(:node).to_s
    return head :unprocessable_entity unless node.match?(/\A\d+\z/)

    run("*1", node, t(".sent", radio: @radio.name, node: node))
  end

  private
    def set_radio
      @radio = Current.user.radios.find(params.expect(:id))
      head :forbidden unless Current.user.can_connect?(@radio)
    end

    def run(function, node, message)
      LinkRequest.remember(@radio, node, Current.user)
      Ami::Client.new(@radio.server).command("rpt fun #{@radio.node} #{function}#{node}")
      redirect_back_or_to dispatch_path, notice: message
    rescue Ami::Error, SystemCallError, IOError, SocketError, Timeout::Error => e
      redirect_back_or_to dispatch_path, alert: t("radios.command_failed", server: @radio.server.name, error: e.message)
    end
end

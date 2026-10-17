# Links of a radio, created and removed from the dispatch screen
class Radios::LinksController < ApplicationController
  before_action :set_radio

  def create
    other = Current.user.radios.find(params.expect(:other_radio_id))
    @radio.link_to!(other, mode: params[:mode], by: Current.user)
    redirect_back_or_to dispatch_path, notice: t(".sent", radio: @radio.name, other: other.name)
  rescue *Server::Ami::CONNECTION_ERRORS => e
    command_failed(e)
  end

  def destroy
    node = params.expect(:node).to_s
    return head :unprocessable_entity unless node.match?(/\A\d+\z/)

    @radio.unlink!(node, by: Current.user)
    redirect_back_or_to dispatch_path, notice: t(".sent", radio: @radio.name, node: node)
  rescue *Server::Ami::CONNECTION_ERRORS => e
    command_failed(e)
  end

  private
    def set_radio
      @radio = Current.user.radios.find(params.expect(:radio_id))
      head :forbidden unless Current.user.can_connect?(@radio)
    end

    def command_failed(error)
      redirect_back_or_to dispatch_path, alert: t("radios.links.command_failed", server: @radio.server.name, error: error.message)
    end
end

# A call from the console's phone (the browser places it)
class PhoneCallsController < ApplicationController
  require_permission :phone

  def create
    number = params.expect(:number).to_s.delete(" -")
    return head :unprocessable_entity unless number.match?(Server::ConsolePhone::NUMBER_FORMAT)

    server = Server.phone_server
    return head :service_unavailable unless server

    render json: server.phone_call(number, Current.user)
  end
end

# The current user's phone extension, for the browser to register it
class PhoneAccountsController < ApplicationController
  require_permission :phone

  def show
    server = Server.phone_server
    return head :service_unavailable unless server && Current.user.phone_account?

    render json: {
      ws: server.webrtc_url,
      host: server.webrtc_host,
      extension: Current.user.sip_extension,
      password: Current.user.sip_password,
      name: Current.user.name
    }
  end
end

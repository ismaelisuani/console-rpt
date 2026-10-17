# Logs in to the server's AMI with the stored credentials
class Admin::Servers::ConnectionChecksController < Admin::BaseController
  require_permission :manage_radios

  def create
    server = Server.find(params.expect(:server_id))
    redirect_to admin_servers_path, notice: t(".ok", server: server.name, version: server.asterisk_version)
  rescue *Server::Ami::CONNECTION_ERRORS => e
    redirect_to admin_servers_path, alert: t(".failed", server: server.name, error: e.message)
  end
end

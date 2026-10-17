module Admin
  class ServersController < BaseController
    require_permission :manage_radios
    before_action :set_server, only: %i[edit update destroy check]

    def index
      @servers = Server.ordered.includes(:radios)
    end

    def new
      @server = Server.new
    end

    def create
      @server = Server.new(server_params)
      if @server.save
        redirect_saved(admin_servers_path, @server, :created)
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      # An empty password field keeps the stored one
      attributes = server_params
      attributes = attributes.except(:ami_password) if attributes[:ami_password].blank?
      if @server.update(attributes)
        redirect_saved(admin_servers_path, @server, :updated)
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      destroy_record(@server, admin_servers_path)
    end

    # Logs in to AMI with the stored credentials
    def check
      version = Ami::Client.new(@server).command("core show version").to_s.lines.first.to_s.strip
      redirect_to admin_servers_path, notice: t(".ok", server: @server.name, version: version)
    rescue Ami::Error, SystemCallError, IOError, SocketError, Timeout::Error => e
      redirect_to admin_servers_path, alert: t(".failed", server: @server.name, error: e.message)
    end

    private
      def set_server
        @server = Server.find(params.expect(:id))
      end

      def server_params
        params.expect(server: %i[name host local ami_port ami_username ami_password ssh_port ssh_username webrtc_url archive_path active])
      end
  end
end

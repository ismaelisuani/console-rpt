module Admin
  class ServersController < BaseController
    require_permission :manage_radios
    before_action :set_server, only: %i[edit update destroy]

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
      if @server.update(server_params)
        redirect_saved(admin_servers_path, @server, :updated)
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      destroy_record(@server, admin_servers_path)
    end

    private
      def set_server
        @server = Server.find(params.expect(:id))
      end

      def server_params
        params.expect(server: %i[name host local ami_port ami_username ami_password ssh_port ssh_username sip_username sip_password webrtc_url archive_path active])
      end
  end
end

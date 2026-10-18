module Admin
  class RadiosController < BaseController
    require_permission :manage_radios
    before_action :set_radio, only: %i[edit update destroy]

    def index
      @page = Radio.includes(:server, :radio_groups).order("servers.name", :position, :name).references(:server).paginate(params[:page])
    end

    def new
      @radio = Radio.new(server: Server.find_by(local: true))
    end

    def create
      @radio = Radio.new(radio_params)
      if @radio.save
        redirect_saved(admin_radios_path, @radio, :created)
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @radio.update(radio_params)
        redirect_saved(admin_radios_path, @radio, :updated)
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      destroy_record(@radio, admin_radios_path)
    end

    private
      def set_radio
        @radio = Radio.find(params.expect(:id))
      end

      def radio_params
        params.expect(radio: [ :server_id, :node, :name, :position, :active, radio_group_ids: [] ])
      end
  end
end

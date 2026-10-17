module Admin
  class RadioGroupsController < BaseController
    require_permission :manage_radios
    before_action :set_radio_group, only: %i[edit update destroy]

    def index
      @radio_groups = RadioGroup.ordered.includes(:radios)
    end

    def new
      @radio_group = RadioGroup.new
    end

    def create
      @radio_group = RadioGroup.new(radio_group_params)
      if @radio_group.save
        redirect_saved(admin_radio_groups_path, @radio_group, :created)
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @radio_group.update(radio_group_params)
        redirect_saved(admin_radio_groups_path, @radio_group, :updated)
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      destroy_record(@radio_group, admin_radio_groups_path)
    end

    private
      def set_radio_group
        @radio_group = RadioGroup.find(params.expect(:id))
      end

      def radio_group_params
        params.expect(radio_group: [ :name, :position, radio_ids: [] ])
      end
  end
end

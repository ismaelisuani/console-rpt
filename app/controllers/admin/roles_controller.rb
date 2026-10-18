module Admin
  class RolesController < BaseController
    require_permission :manage_users
    before_action :set_role, only: %i[edit update destroy]

    def index
      @page = Role.order(:name).includes(:users).paginate(params[:page])
    end

    def new
      @role = Role.new
    end

    def create
      @role = Role.new(role_params)
      if @role.save
        redirect_saved(admin_roles_path, @role, :created)
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @role.update(role_params)
        redirect_saved(admin_roles_path, @role, :updated)
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      destroy_record(@role, admin_roles_path)
    end

    private
      def set_role
        @role = Role.find(params.expect(:id))
      end

      def role_params
        params.expect(role: [ :name, permissions: [] ])
      end
  end
end

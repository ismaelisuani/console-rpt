module Admin
  class UsersController < BaseController
    require_permission :manage_users
    before_action :set_user, only: %i[edit update destroy]

    def index
      @users = User.ordered.includes(:role, :radio_groups)
    end

    def new
      @user = User.new(role: Role.order(:name).last)
    end

    def create
      @user = User.new(user_params)
      if @user.save
        redirect_saved(admin_users_path, @user, :created)
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @user.update(user_params)
        redirect_saved(admin_users_path, @user, :updated)
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      destroy_record(@user, admin_users_path)
    end

    private
      def set_user
        @user = User.find(params.expect(:id))
      end

      def user_params
        params.expect(user: [ :name, :username, :email_address, :role_id, :locale, :active, :password, :password_confirmation,
          group_levels: {} ])
      end
  end
end

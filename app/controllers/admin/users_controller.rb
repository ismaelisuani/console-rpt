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
      attributes = user_params
      attributes = attributes.except(:password, :password_confirmation) if attributes[:password].blank?
      if @user == Current.user && attributes[:active] == "0"
        @user.errors.add(:active, :self)
        return render :edit, status: :unprocessable_entity
      end

      if @user.update(attributes)
        redirect_saved(admin_users_path, @user, :updated)
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      return redirect_to admin_users_path, alert: t(".self") if @user == Current.user

      destroy_record(@user, admin_users_path)
    end

    private
      def set_user
        @user = User.find(params.expect(:id))
      end

      def user_params
        params.expect(user: [ :name, :email_address, :role_id, :locale, :active, :password, :password_confirmation,
          group_levels: {} ])
      end
  end
end

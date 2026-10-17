class ProfilesController < ApplicationController
  before_action { @user = Current.user }

  def show
  end

  def update
    if @user.update(params.expect(user: %i[locale password password_confirmation]))
      redirect_to profile_path, notice: t(".updated", locale: @user.locale)
    else
      render :show, status: :unprocessable_entity
    end
  end
end

class ProfilesController < ApplicationController
  before_action { @user = Current.user }

  def show
  end

  def update
    attributes = params.expect(user: %i[locale password password_confirmation])
    attributes = attributes.except(:password, :password_confirmation) if attributes[:password].blank?

    if @user.update(attributes)
      redirect_to profile_path, notice: t(".updated", locale: @user.locale)
    else
      render :show, status: :unprocessable_entity
    end
  end
end

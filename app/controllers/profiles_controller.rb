class ProfilesController < ApplicationController
  before_action { @user = Current.user }

  def show
  end

  def update
    respond_to do |format|
      if @user.update(params.expect(user: %i[locale theme password password_confirmation]))
        format.html { redirect_to profile_path, notice: t(".updated", locale: @user.locale) }
        format.json { head :no_content }
      else
        format.html { render :show, status: :unprocessable_entity }
        format.json { head :unprocessable_entity }
      end
    end
  end
end

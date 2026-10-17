# Units loaded from a CSV file
class Units::ImportsController < ApplicationController
  require_permission :manage_units

  def new
  end

  def create
    @result = Unit.import(params.expect(:file))
    if @result.errors.any?
      flash.now[:alert] = @result.errors.first(10).join(" · ")
      render :new, status: :unprocessable_entity
    else
      redirect_to units_path, notice: t(".done", created: @result.created, updated: @result.updated)
    end
  rescue ActionController::ParameterMissing
    redirect_to new_units_import_path, alert: t(".no_file")
  end
end

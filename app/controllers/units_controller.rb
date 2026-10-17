class UnitsController < ApplicationController
  require_permission :manage_units
  before_action :set_unit, only: %i[edit update destroy]

  def index
    @query = params[:q].to_s.strip
    @units = Unit.ordered
    if @query.present?
      pattern = "%#{Unit.sanitize_sql_like(@query)}%"
      @units = @units.where("identifier ILIKE :q OR name ILIKE :q OR person ILIKE :q OR fleet ILIKE :q", q: pattern)
    end
  end

  # Also the quick add from the dispatch screen, with decoder and identifier filled in
  def new
    @unit = Unit.new(params.permit(:decoder, :identifier))
  end

  def create
    @unit = Unit.new(unit_params)
    if @unit.save
      redirect_to units_path, notice: t("flash.created", resource: Unit.model_name.human)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @unit.update(unit_params)
      redirect_to units_path, notice: t("flash.updated", resource: Unit.model_name.human)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @unit.destroy
    redirect_to units_path, notice: t("flash.destroyed", resource: Unit.model_name.human)
  end

  def new_import
  end

  def import
    result = Unit::Import.new(params.expect(:file)).run
    if result.errors.any?
      flash.now[:alert] = result.errors.first(10).join(" · ")
      @result = result
      render :new_import, status: :unprocessable_entity
    else
      redirect_to units_path, notice: t(".done", created: result.created, updated: result.updated)
    end
  rescue ActionController::ParameterMissing
    redirect_to import_units_path, alert: t(".no_file")
  end

  private
    def set_unit
      @unit = Unit.find(params.expect(:id))
    end

    def unit_params
      params.expect(unit: %i[identifier decoder name person fleet active])
    end
end

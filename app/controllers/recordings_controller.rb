class RecordingsController < ApplicationController
  require_permission :view_recordings

  def index
    @filters = params.permit(:radio_id, :direction, :from, :to, :unit, :page)
    @page = Recording.visible_to(Current.user).filtered(@filters).recent.includes(:radio, :server).paginate(@filters[:page], per: 50)
  end
end

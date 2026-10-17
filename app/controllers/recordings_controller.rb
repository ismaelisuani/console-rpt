class RecordingsController < ApplicationController
  require_permission :view_recordings

  def index
    @filters = params.permit(:radio_id, :direction, :from, :to, :unit, :page)
    @recordings = Recording.visible_to(Current.user).filtered(@filters).recent.page(@filters[:page])
      .includes(:radio, :server).to_a
  end
end

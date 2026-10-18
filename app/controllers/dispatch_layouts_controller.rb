# The arrangement of the radio tiles, saved as the user moves them
class DispatchLayoutsController < ApplicationController
  before_action :set_dispatch_layout

  def update
    @dispatch_layout.update!(tiles: params.expect(tiles: [ [ :radio_id, :x, :y ] ]))
    head :no_content
  end

  private
    def set_dispatch_layout
      group = Current.user.visible_radio_groups.find_by(id: params[:group_id])
      @dispatch_layout = Current.user.dispatch_layout_for(group)
    end
end

# The arrangement of the radio tiles, saved as the user moves or resizes them
class DispatchLayoutsController < ApplicationController
  before_action :set_dispatch_layout

  def update
    @dispatch_layout.update!(tiles: params.expect(tiles: [ [ :radio_id, :w, :h ] ]))
    head :no_content
  end

  def destroy
    @dispatch_layout.destroy if @dispatch_layout.persisted?
    redirect_to dispatch_path(group_id: @dispatch_layout.radio_group_id)
  end

  private
    def set_dispatch_layout
      group = Current.user.visible_radio_groups.find_by(id: params[:group_id])
      @dispatch_layout = Current.user.dispatch_layout_for(group)
    end
end

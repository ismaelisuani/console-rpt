class DispatchController < ApplicationController
  before_action { redirect_to profile_path unless can?(:view_dispatch) }

  def show
    @groups = Current.user.visible_radio_groups.ordered.to_a
    # No group: all the user's radios
    @group = @groups.find { |group| group.id == params[:group_id].to_i }
    @dispatch_layout = Current.user.dispatch_layout_for(@group)
    @radios = @dispatch_layout.arrange(radios_to_show)
    # three columns and three rows per screen; users arrange and size the tiles
    @layout = "9"
    @events = RadioEvent.where(radio: @radios).recent.limit(30).includes(:radio, :user).to_a
  end

  private
    def radios_to_show
      visible = Current.user.radios.active
      radios = if @group
        @group.radios.merge(visible).order("radio_group_memberships.position", :position, :name)
      else
        visible.ordered
      end
      radios.includes(:server).to_a
    end
end

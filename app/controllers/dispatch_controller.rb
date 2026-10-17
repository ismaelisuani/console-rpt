class DispatchController < ApplicationController
  LAYOUTS = %w[4 6 9].freeze

  before_action { redirect_to profile_path unless can?(:view_dispatch) }

  def show
    @groups = Current.user.visible_radio_groups.ordered.to_a
    @group = @groups.find { |group| group.id == params[:group_id].to_i } || @groups.first
    @radios = radios_to_show
    @layout = params[:layout].presence_in(LAYOUTS) || cookies[:dispatch_layout].presence_in(LAYOUTS) || "6"
    cookies.permanent[:dispatch_layout] = @layout
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

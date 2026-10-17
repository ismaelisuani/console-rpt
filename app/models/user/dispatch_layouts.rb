# Each user's arrangement of the dispatch screen, per radio group
module User::DispatchLayouts
  extend ActiveSupport::Concern

  included do
    has_many :dispatch_layouts, dependent: :destroy
  end

  def dispatch_layout_for(radio_group)
    dispatch_layouts.find_or_initialize_by(radio_group: radio_group)
  end
end

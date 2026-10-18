# The air archive doesn't know who talked from the console (for app_rpt it is
# the node itself), but the console logged each PTT with its user: a
# transmission recording takes the user of the PTT that started it
module Recording::ConsoleOperator
  extend ActiveSupport::Concern

  # How far apart the recording's start and the logged PTT can be
  MATCH_WINDOW = 3.seconds

  included do
    belongs_to :user, optional: true
  end

  class_methods do
    def assign_console_operators(recordings)
      recordings.where(direction: "tx", user_id: nil, other_node: nil).where.not(radio_id: nil).find_each(&:assign_console_operator)
    end
  end

  def assign_console_operator
    candidates = RadioEvent.where(radio_id: radio_id, kind: "transmit_start", occurred_at: (started_at - MATCH_WINDOW)..(started_at + MATCH_WINDOW))
      .where.not(user_id: nil)
    event = candidates.min_by { |candidate| (candidate.occurred_at - started_at).abs }
    update_columns(user_id: event.user_id) if event
  end
end

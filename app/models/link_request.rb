# Who asked for a link change from the console, so the activity log can name
# them when app_rpt reports the change a moment later (the AMI listener runs
# in another process)
class LinkRequest < ApplicationRecord
  TTL = 30.seconds

  belongs_to :radio
  belongs_to :user

  def self.remember(radio, node, user)
    where(created_at: ...TTL.ago).delete_all
    create!(radio: radio, other_node: node, user: user)
  end

  # The user id of the latest pending request, consumed
  def self.take(radio, node)
    request = where(radio: radio, other_node: node, created_at: TTL.ago..).order(:created_at).last
    request&.destroy
    request&.user_id
  end
end

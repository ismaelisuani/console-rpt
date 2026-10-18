# The new recordings of every server, every minute (config/recurring.yml),
# and of one server right after one of its radios stops receiving or
# transmitting (Radio::LiveState)
class RecordingsSyncJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: ->(server_id = nil) { "recordings-#{server_id || "all"}" }, duration: 5.minutes

  def perform(server_id = nil)
    servers = server_id ? Server.active.where(id: server_id) : Server.active
    servers.find_each(&:sync_recordings)
  end
end

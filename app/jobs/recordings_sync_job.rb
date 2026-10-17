# Every minute (config/recurring.yml): the new recordings of every server
class RecordingsSyncJob < ApplicationJob
  queue_as :default

  def perform
    Server.active.find_each(&:sync_recordings)
  end
end

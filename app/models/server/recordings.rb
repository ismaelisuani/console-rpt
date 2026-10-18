require "open3"

# The server's air archive into the recordings: read in place on the local
# server; copied over SSH (rsync) from the other servers
module Server::Recordings
  extend ActiveSupport::Concern

  class SyncError < StandardError; end

  # Files changed this long before the last sync are looked at again
  SYNC_MARGIN = 5.minutes

  included do
    has_many :recordings, dependent: :delete_all
    validates :time_zone, inclusion: { in: ->(_) { ActiveSupport::TimeZone::MAPPING.values.uniq } }
  end

  def archive_root
    local? ? Pathname(archive_path) : Rails.configuration.x.archives_dir.join(id.to_s)
  end

  # For the recurring job: errors are kept on the server, not raised
  def sync_recordings
    sync_recordings!
  rescue SyncError, SystemCallError => e
    update_columns(recordings_sync_error: e.message.truncate(250))
  end

  def sync_recordings!
    started = Time.current
    copy_remote_archive unless local?
    imported = import_recordings(changed_since: recordings_synced_at && recordings_synced_at - SYNC_MARGIN)
    update_columns(recordings_synced_at: started, recordings_sync_error: nil)
    # open recordings pages reload their list (each with its own filters)
    Turbo::StreamsChannel.broadcast_refresh_to(:recordings) if imported.positive?
  end

  private
    def copy_remote_archive
      raise SyncError, I18n.t("servers.recordings.no_ssh_user") if ssh_username.blank?

      archive_root.mkpath
      command = [ "rsync", "-a", "--include=*/", "--include=*.txt", "--include=*.WAV", "--include=*.wav", "--exclude=*",
        "-e", "ssh -p #{ssh_port} -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10" ]
      command << "--rsync-path=sudo rsync" if ssh_sudo?
      command += [ "#{ssh_username}@#{host}:#{archive_path.chomp("/")}/", "#{archive_root}/" ]
      output, status = Open3.capture2e(*command)
      raise SyncError, output.lines.last.to_s.strip unless status.success?
    end

    def import_recordings(changed_since:)
      radio_ids = radios.pluck(:node, :id).to_h
      rows = archive_root.glob("*/*.txt").filter_map do |file|
        next if changed_since && file.mtime < changed_since

        attributes = Recording.attributes_from_archive(file.read, server: self, node_dir: file.dirname.basename.to_s)
        attributes&.merge(radio_id: radio_ids[attributes[:node]])
      end
      ids = rows.each_slice(500).flat_map { |slice| Recording.insert_all(slice, unique_by: %i[server_id link_id]).rows.flatten }
      Recording.assign_console_operators(Recording.where(id: ids))
      ids.size
    end
end

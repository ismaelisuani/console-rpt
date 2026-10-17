class AddRecordingsSyncErrorToServers < ActiveRecord::Migration[8.1]
  def change
    add_column :servers, :recordings_sync_error, :string
  end
end

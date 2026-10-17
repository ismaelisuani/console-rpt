class CreateRecordings < ActiveRecord::Migration[8.1]
  def change
    create_table :recordings do |t|
      t.references :server, null: false, foreign_key: true
      t.references :radio, foreign_key: true
      t.string :node, null: false
      # LinkId of the archive: unique per server, also the file name
      t.string :link_id, null: false
      t.string :direction, null: false
      t.datetime :started_at, null: false
      t.decimal :duration, precision: 8, scale: 2, null: false, default: 0
      # Dato8: the unit ID of a reception, or the link that keyed up a transmission
      t.string :unit_identifier
      t.string :other_node
      t.string :decoder
      # Dato9
      t.string :remote_node
      # Audio, relative to the server's archive (or its synced copy)
      t.string :audio_path, null: false

      t.timestamps
    end
    add_index :recordings, %i[server_id link_id], unique: true
    add_index :recordings, :started_at
    add_index :recordings, %i[decoder unit_identifier]

    change_table :servers do |t|
      t.string :time_zone, null: false, default: "America/Argentina/Buenos_Aires"
      t.boolean :ssh_sudo, null: false, default: false
      t.datetime :recordings_synced_at
    end
  end
end

class CreateServers < ActiveRecord::Migration[8.1]
  def change
    create_table :servers do |t|
      t.string :name, null: false
      t.string :host, null: false
      t.boolean :local, null: false, default: false
      t.integer :ami_port, null: false, default: 5038
      t.string :ami_username, null: false
      t.string :ami_password, null: false
      t.integer :ssh_port, null: false, default: 22
      t.string :ssh_username
      t.string :webrtc_url
      t.string :archive_path, null: false, default: "/var/spool/asterisk/archive"
      t.boolean :active, null: false, default: true
      t.boolean :online, null: false, default: false
      t.datetime :status_changed_at

      t.timestamps
    end
    add_index :servers, :name, unique: true
  end
end

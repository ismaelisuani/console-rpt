class AddSipAccountToUsers < ActiveRecord::Migration[8.1]
  def change
    # The user's own phone extension (a PJSIP endpoint the console provisions)
    add_column :users, :sip_extension, :string
    add_column :users, :sip_password, :string
    add_index :users, :sip_extension, unique: true

    # Where the server's Asterisk configuration is (the console writes its
    # generated files there)
    add_column :servers, :asterisk_config_path, :string, null: false, default: "/etc/asterisk"
  end
end

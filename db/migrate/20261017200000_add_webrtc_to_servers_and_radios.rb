class AddWebrtcToServersAndRadios < ActiveRecord::Migration[8.1]
  def change
    change_table :servers do |t|
      t.string :sip_username, null: false, default: "webconsole"
      t.string :sip_password
      t.string :console_secret
    end

    change_table :radios do |t|
      # The console user who pressed PTT last, to name console transmissions
      t.references :ptt_user, foreign_key: { to_table: :users }
      t.datetime :ptt_at
      t.references :transmitted_by_user, foreign_key: { to_table: :users }
    end
  end
end

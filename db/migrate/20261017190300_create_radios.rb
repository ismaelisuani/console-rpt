class CreateRadios < ActiveRecord::Migration[8.1]
  def change
    create_table :radios do |t|
      t.references :server, null: false, foreign_key: true
      t.string :node, null: false
      t.string :name, null: false
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true

      # Live state, kept up to date by the AMI listener
      t.boolean :receiving, null: false, default: false
      t.boolean :transmitting, null: false, default: false
      t.string :transmitted_by
      t.string :last_unit_identifier
      t.string :last_decoder
      t.jsonb :links, null: false, default: []
      t.datetime :state_changed_at
      t.datetime :last_activity_at

      t.timestamps
    end
    add_index :radios, %i[server_id node], unique: true

    create_table :radio_groups do |t|
      t.string :name, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end
    add_index :radio_groups, :name, unique: true

    create_table :radio_group_memberships do |t|
      t.references :radio_group, null: false, foreign_key: true
      t.references :radio, null: false, foreign_key: true
      t.integer :position, null: false, default: 0

      t.timestamps
    end
    add_index :radio_group_memberships, %i[radio_group_id radio_id], unique: true

    create_table :radio_group_accesses do |t|
      t.references :user, null: false, foreign_key: true
      t.references :radio_group, null: false, foreign_key: true
      t.string :level, null: false, default: "operate"

      t.timestamps
    end
    add_index :radio_group_accesses, %i[user_id radio_group_id], unique: true
  end
end

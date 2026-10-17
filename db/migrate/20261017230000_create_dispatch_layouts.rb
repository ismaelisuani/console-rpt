class CreateDispatchLayouts < ActiveRecord::Migration[8.1]
  def change
    # How each user arranged the radio tiles of a group (or of all their radios)
    create_table :dispatch_layouts do |t|
      t.references :user, null: false, foreign_key: true
      t.references :radio_group, foreign_key: true
      t.jsonb :tiles, null: false, default: []

      t.timestamps
    end
    add_index :dispatch_layouts, %i[user_id radio_group_id], unique: true, nulls_not_distinct: true
  end
end

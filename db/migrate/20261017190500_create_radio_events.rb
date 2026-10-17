class CreateRadioEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :radio_events do |t|
      t.references :radio, foreign_key: true
      t.references :server, foreign_key: true
      t.references :user, foreign_key: true
      t.string :kind, null: false
      t.string :unit_identifier
      t.string :decoder
      t.string :other_node
      t.datetime :occurred_at, null: false

      t.timestamps
    end
    add_index :radio_events, :occurred_at
  end
end

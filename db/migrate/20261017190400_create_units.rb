class CreateUnits < ActiveRecord::Migration[8.1]
  def change
    create_table :units do |t|
      t.string :identifier, null: false
      t.string :decoder, null: false
      t.string :name, null: false
      t.string :person
      t.string :fleet
      t.boolean :active, null: false, default: true

      t.timestamps
    end
    add_index :units, %i[decoder identifier], unique: true
  end
end

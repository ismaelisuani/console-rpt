class CreateRolesAndExtendUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :roles do |t|
      t.string :name, null: false
      t.string :permissions, array: true, null: false, default: []

      t.timestamps
    end
    add_index :roles, :name, unique: true

    change_table :users do |t|
      t.string :name, null: false, default: ""
      t.string :locale, null: false, default: "es"
      t.references :role, null: false, foreign_key: true
      t.boolean :active, null: false, default: true
    end
  end
end

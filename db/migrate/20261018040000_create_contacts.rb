class CreateContacts < ActiveRecord::Migration[8.1]
  def change
    # The phone's address book, shared by the console users
    create_table :contacts do |t|
      t.string :name, null: false
      t.string :number, null: false
      t.string :organization

      t.timestamps
    end
    add_index :contacts, :name

    # Each user's favorites, one click away in the phone
    create_table :contact_favorites do |t|
      t.references :user, null: false, foreign_key: true
      t.references :contact, null: false, foreign_key: true

      t.timestamps
    end
    add_index :contact_favorites, %i[user_id contact_id], unique: true
  end
end

class AddUsernameToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :username, :string
    execute "UPDATE users SET username = lower(split_part(email_address, '@', 1)) || CASE WHEN id > 1 THEN id::text ELSE '' END"
    change_column_null :users, :username, false
    add_index :users, :username, unique: true
    change_column_null :users, :email_address, true
  end

  def down
    change_column_null :users, :email_address, false
    remove_column :users, :username
  end
end

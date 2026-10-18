class AddUserToRecordings < ActiveRecord::Migration[8.1]
  def change
    # The console user who talked, for transmissions made from the console
    add_reference :recordings, :user, foreign_key: { on_delete: :nullify }
  end
end

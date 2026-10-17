class SplitRadioStateTimes < ActiveRecord::Migration[8.1]
  def change
    rename_column :radios, :state_changed_at, :receiving_since
    add_column :radios, :transmitting_since, :datetime
  end
end

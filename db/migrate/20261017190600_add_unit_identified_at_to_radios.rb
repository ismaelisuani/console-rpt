class AddUnitIdentifiedAtToRadios < ActiveRecord::Migration[8.1]
  def change
    add_column :radios, :unit_identified_at, :datetime
  end
end

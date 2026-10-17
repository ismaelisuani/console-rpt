class CreateLinkRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :link_requests do |t|
      t.references :radio, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :other_node, null: false

      t.timestamps
    end
  end
end

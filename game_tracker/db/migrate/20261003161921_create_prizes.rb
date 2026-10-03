class CreatePrizes < ActiveRecord::Migration[8.1]
  def change
    create_table :prizes do |t|
      t.references :group, null: false, foreign_key: true
      t.date :month, null: false
      t.string :description, null: false

      t.timestamps
    end
    add_index :prizes, [ :group_id, :month ], unique: true
  end
end

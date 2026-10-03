class CreateResults < ActiveRecord::Migration[8.1]
  def change
    create_table :results do |t|
      t.references :user, null: false, foreign_key: true
      t.string :game, null: false
      t.date :played_on, null: false
      t.integer :puzzle_number
      t.boolean :solved, null: false, default: false
      t.integer :score_value
      t.string :breakdown
      t.decimal :points, precision: 4, scale: 1, null: false, default: 0
      t.text :share_text

      t.timestamps
    end
    add_index :results, [ :user_id, :game, :played_on ], unique: true
    add_index :results, :played_on
  end
end

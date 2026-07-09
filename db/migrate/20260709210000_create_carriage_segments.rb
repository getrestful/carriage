class CreateCarriageSegments < ActiveRecord::Migration[8.1]
  def change
    create_table :carriage_segments do |t|
      t.references :list, null: false, foreign_key: { to_table: :carriage_lists }
      t.string :name, null: false
      t.string :match_type, null: false, default: "all"
      t.json :conditions, null: false, default: []
      t.timestamps
    end
    add_index :carriage_segments, [ :list_id, :name ], unique: true, name: "index_carriage_segments_on_list_and_name"
  end
end

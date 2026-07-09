class CreateCarriageLists < ActiveRecord::Migration[8.1]
  def change
    create_table :carriage_lists do |t|
      t.string :name, null: false
      t.text :description
      t.timestamps
    end
    add_index :carriage_lists, :name, unique: true
  end
end

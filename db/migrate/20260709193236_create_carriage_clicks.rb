class CreateCarriageClicks < ActiveRecord::Migration[8.1]
  def change
    create_table :carriage_clicks do |t|
      t.references :delivery, null: false, foreign_key: { to_table: :carriage_deliveries }
      t.string :token, null: false
      t.text :url, null: false
      t.integer :click_count, null: false, default: 0
      t.datetime :clicked_at
      t.timestamps
    end
    add_index :carriage_clicks, :token, unique: true
  end
end

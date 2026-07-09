class CreateCarriageDeliveries < ActiveRecord::Migration[8.1]
  def change
    create_table :carriage_deliveries do |t|
      t.references :campaign, null: false, foreign_key: { to_table: :carriage_campaigns }
      t.references :subscriber, null: false, foreign_key: { to_table: :carriage_subscribers }
      t.string :token, null: false
      t.string :state, null: false, default: "pending"
      t.boolean :is_test, null: false, default: false
      t.text :error_message
      t.datetime :sent_at
      t.datetime :opened_at
      t.timestamps
    end
    add_index :carriage_deliveries, [ :campaign_id, :subscriber_id ], unique: true, name: "index_carriage_deliveries_on_campaign_and_subscriber"
    add_index :carriage_deliveries, :token, unique: true
  end
end

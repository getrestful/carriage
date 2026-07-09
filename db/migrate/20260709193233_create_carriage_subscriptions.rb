class CreateCarriageSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :carriage_subscriptions do |t|
      t.references :list, null: false, foreign_key: { to_table: :carriage_lists }
      t.references :subscriber, null: false, foreign_key: { to_table: :carriage_subscribers }
      t.datetime :unsubscribed_at
      t.timestamps
    end
    add_index :carriage_subscriptions, [ :list_id, :subscriber_id ], unique: true, name: "index_carriage_subscriptions_on_list_and_subscriber"
  end
end

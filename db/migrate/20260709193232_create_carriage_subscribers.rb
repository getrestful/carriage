class CreateCarriageSubscribers < ActiveRecord::Migration[8.1]
  def change
    create_table :carriage_subscribers do |t|
      t.string :email, null: false
      t.string :first_name
      t.string :last_name
      t.timestamps
    end
    add_index :carriage_subscribers, :email, unique: true
  end
end

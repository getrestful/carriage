class AddConfirmationSentAtToCarriageSubscriptions < ActiveRecord::Migration[8.1]
  def change
    add_column :carriage_subscriptions, :confirmation_sent_at, :datetime

    # Pending subscriptions got their only confirmation email on creation.
    reversible do |dir|
      dir.up do
        execute "UPDATE carriage_subscriptions SET confirmation_sent_at = created_at WHERE confirmed_at IS NULL"
      end
    end
  end
end

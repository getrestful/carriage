class AddConfirmationToCarriageSubscriptions < ActiveRecord::Migration[8.1]
  def change
    add_column :carriage_subscriptions, :confirmed_at, :datetime

    # No stored confirmation_token column — confirmation links use Rails'
    # generates_token_for (see Carriage::Subscription), which derives a
    # signed, expiring token on demand instead of persisting a secret
    # plaintext token that anyone with DB read access could reuse.

    # Subscriptions created before double opt-in existed were never asked to
    # confirm — treat them as confirmed as of their creation so this migration
    # doesn't silently drop existing subscribers out of send-eligibility.
    reversible do |dir|
      dir.up do
        execute "UPDATE carriage_subscriptions SET confirmed_at = created_at WHERE confirmed_at IS NULL"
      end
    end
  end
end

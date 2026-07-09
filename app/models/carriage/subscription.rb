module Carriage
  class Subscription < ApplicationRecord
    belongs_to :list, class_name: "Carriage::List"
    belongs_to :subscriber, class_name: "Carriage::Subscriber"

    validates :subscriber_id, uniqueness: { scope: :list_id }

    scope :active, -> { where(unsubscribed_at: nil) }

    after_create :subscribe_via_mailkick

    def unsubscribe!
      update!(unsubscribed_at: Time.current)
      subscriber.unsubscribe(list.name)
    end

    private

    # Mailkick's own subscribe/unsubscribe bookkeeping is kept in sync as a courtesy;
    # unsubscribed_at above is Carriage's own source of truth for send-eligibility,
    # since mailkick has no durable opt-out state (its "unsubscribe" hard-deletes the row).
    def subscribe_via_mailkick
      subscriber.subscribe(list.name)
    end
  end
end

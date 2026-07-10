module Carriage
  class Subscription < ApplicationRecord
    belongs_to :list, class_name: "Carriage::List"
    belongs_to :subscriber, class_name: "Carriage::Subscriber"

    # Set by SignupsController to opt a subscription created through the public
    # signup form out of auto-confirmation — see #auto_confirm below. Every other
    # creation path (admin "add subscriber", CSV import, tests) is unaffected and
    # keeps behaving as it did before double opt-in existed.
    attr_accessor :require_confirmation

    validates :subscriber_id, uniqueness: { scope: :list_id }

    # Only counts subscribers who both confirmed and never unsubscribed as
    # send-eligible — List#active_subscribers/Segment#active_subscribers funnel
    # through this scope, so campaigns never mail an unconfirmed address.
    scope :active, -> { where(unsubscribed_at: nil).where.not(confirmed_at: nil) }
    scope :pending_confirmation, -> { where(confirmed_at: nil, unsubscribed_at: nil) }

    # Signed, expiring confirmation token — derived on demand (via
    # generate_token_for/find_by_token_for below), not stored in the DB. No
    # block keying it to an attribute: re-clicking an already-used link within
    # the expiry window still resolves the record (confirm! is idempotent),
    # matching the "click twice, still fine" UX rather than one-time-use.
    generates_token_for :confirm_subscription, expires_in: 3.days

    before_validation :auto_confirm, on: :create, unless: :require_confirmation

    after_create :subscribe_via_mailkick
    after_create :send_confirmation_email, if: -> { confirmed_at.nil? }

    def confirmed?
      confirmed_at.present?
    end

    # Carriage::Subscription's own unsubscribed_at/confirmed_at are the source
    # of truth for this — never derive display status from mailkick's
    # subscribed?, which flips true on creation regardless of confirmation.
    def status
      return :unsubscribed if unsubscribed_at.present?
      return :pending if confirmed_at.nil?

      :subscribed
    end

    def confirm!
      update!(confirmed_at: Time.current) if confirmed_at.nil?
    end

    def send_confirmation_email
      Carriage::ConfirmationMailer.confirm_email(self).deliver_later
    end

    def unsubscribe!
      update!(unsubscribed_at: Time.current)
      subscriber.unsubscribe(list.name)
    end

    def resubscribe!
      update!(unsubscribed_at: nil)
      subscriber.subscribe(list.name)
    end

    private

    def auto_confirm
      self.confirmed_at ||= Time.current
    end

    # Mailkick's own subscribe/unsubscribe bookkeeping is kept in sync as a courtesy;
    # unsubscribed_at above is Carriage's own source of truth for send-eligibility,
    # since mailkick has no durable opt-out state (its "unsubscribe" hard-deletes the row).
    def subscribe_via_mailkick
      subscriber.subscribe(list.name)
    end
  end
end

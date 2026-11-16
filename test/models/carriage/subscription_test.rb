require "test_helper"

module Carriage
  class SubscriptionTest < ActiveSupport::TestCase
    include ActionMailer::TestHelper

    test "creating a subscription subscribes via mailkick" do
      list = Carriage::List.create!(name: "Weekly")
      subscriber = Carriage::Subscriber.create!(email: "a@example.com")

      Carriage::Subscription.create!(list: list, subscriber: subscriber)

      assert subscriber.subscribed?(list.name)
    end

    test "unsubscribe! sets unsubscribed_at and clears mailkick subscription" do
      list = Carriage::List.create!(name: "Weekly")
      subscriber = Carriage::Subscriber.create!(email: "a@example.com")
      subscription = Carriage::Subscription.create!(list: list, subscriber: subscriber)

      subscription.unsubscribe!

      assert subscription.unsubscribed_at.present?
      assert_not subscriber.subscribed?(list.name)
    end

    test "is unique per list and subscriber" do
      list = Carriage::List.create!(name: "Weekly")
      subscriber = Carriage::Subscriber.create!(email: "a@example.com")
      Carriage::Subscription.create!(list: list, subscriber: subscriber)

      duplicate = Carriage::Subscription.new(list: list, subscriber: subscriber)

      assert_not duplicate.valid?
    end

    test "is auto-confirmed by default" do
      list = Carriage::List.create!(name: "Weekly")
      subscriber = Carriage::Subscriber.create!(email: "a@example.com")

      subscription = Carriage::Subscription.create!(list: list, subscriber: subscriber)

      assert subscription.confirmed?
      assert_includes Carriage::Subscription.active, subscription
    end

    test "require_confirmation: true leaves the subscription unconfirmed and sends a confirmation email" do
      list = Carriage::List.create!(name: "Weekly")
      subscriber = Carriage::Subscriber.create!(email: "a@example.com")

      subscription = nil
      assert_enqueued_jobs 1, only: Carriage::MailDeliveryJob do
        subscription = Carriage::Subscription.create!(list: list, subscriber: subscriber, require_confirmation: true)
      end

      assert_not subscription.confirmed?
      assert_not_includes Carriage::Subscription.active, subscription
    end

    test "confirm! marks the subscription confirmed and makes it active" do
      list = Carriage::List.create!(name: "Weekly")
      subscriber = Carriage::Subscriber.create!(email: "a@example.com")
      subscription = Carriage::Subscription.create!(list: list, subscriber: subscriber, require_confirmation: true)

      subscription.confirm!

      assert subscription.confirmed_at.present?
      assert_includes Carriage::Subscription.active, subscription
    end

    test "generates a token that resolves back to the subscription via find_by_token_for" do
      list = Carriage::List.create!(name: "Weekly")
      subscriber = Carriage::Subscriber.create!(email: "a@example.com")
      subscription = Carriage::Subscription.create!(list: list, subscriber: subscriber, require_confirmation: true)

      token = subscription.generate_token_for(:confirm_subscription)

      assert_equal subscription, Carriage::Subscription.find_by_token_for(:confirm_subscription, token)
      assert_nil Carriage::Subscription.find_by_token_for(:confirm_subscription, "not-a-real-token")
    end

    test "status reflects confirmation and unsubscribe state, not mailkick" do
      list = Carriage::List.create!(name: "Weekly")

      confirmed = Carriage::Subscription.create!(list: list, subscriber: Carriage::Subscriber.create!(email: "a@example.com"))
      pending = Carriage::Subscription.create!(list: list, subscriber: Carriage::Subscriber.create!(email: "b@example.com"), require_confirmation: true)
      unsubscribed = Carriage::Subscription.create!(list: list, subscriber: Carriage::Subscriber.create!(email: "c@example.com"))
      unsubscribed.unsubscribe!

      assert_equal :subscribed, confirmed.status
      assert_equal :pending, pending.status
      assert_equal :unsubscribed, unsubscribed.status
      # mailkick's own bookkeeping is a courtesy sync, not the source of truth —
      # it flips true on creation regardless of confirmation, so #status must
      # never derive from it.
      assert pending.subscriber.subscribed?(list.name)
    end

    test "renew_confirmation sends a fresh confirmation email to a pending subscription" do
      subscription = create_pending_subscription
      subscription.update_column(:confirmation_sent_at, 1.hour.ago)

      assert_enqueued_jobs 1, only: Carriage::MailDeliveryJob do
        subscription.renew_confirmation
      end

      assert_equal :pending, subscription.status
      assert_in_delta Time.current, subscription.confirmation_sent_at, 5.seconds
    end

    test "renew_confirmation does not resend within the resend interval" do
      subscription = create_pending_subscription

      assert_no_enqueued_jobs only: Carriage::MailDeliveryJob do
        subscription.renew_confirmation
      end
    end

    test "renew_confirmation puts an unsubscribed subscription back to pending and emails a confirmation link" do
      list = Carriage::List.create!(name: "Weekly")
      subscriber = Carriage::Subscriber.create!(email: "a@example.com")
      subscription = Carriage::Subscription.create!(list: list, subscriber: subscriber)
      subscription.unsubscribe!

      assert_enqueued_jobs 1, only: Carriage::MailDeliveryJob do
        subscription.renew_confirmation
      end

      assert_equal :pending, subscription.reload.status
      assert_not_includes Carriage::Subscription.active, subscription
      assert subscriber.subscribed?(list.name)

      subscription.confirm!
      assert_equal :subscribed, subscription.status
    end

    test "renew_confirmation leaves a confirmed subscription alone" do
      list = Carriage::List.create!(name: "Weekly")
      subscriber = Carriage::Subscriber.create!(email: "a@example.com")
      subscription = Carriage::Subscription.create!(list: list, subscriber: subscriber)

      assert_no_enqueued_jobs only: Carriage::MailDeliveryJob do
        subscription.renew_confirmation
      end

      assert_equal :subscribed, subscription.status
    end

    private

    def create_pending_subscription
      list = Carriage::List.create!(name: "Weekly")
      subscriber = Carriage::Subscriber.create!(email: "a@example.com")
      Carriage::Subscription.create!(list: list, subscriber: subscriber, require_confirmation: true)
    end
  end
end

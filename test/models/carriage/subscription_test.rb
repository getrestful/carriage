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
      assert_enqueued_jobs 1, only: ActionMailer::MailDeliveryJob do
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
  end
end

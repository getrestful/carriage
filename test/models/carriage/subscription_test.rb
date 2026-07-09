require "test_helper"

module Carriage
  class SubscriptionTest < ActiveSupport::TestCase
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
  end
end

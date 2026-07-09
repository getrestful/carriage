require "test_helper"

module Carriage
  class SubscriberTest < ActiveSupport::TestCase
    test "normalizes email to lowercase and strips whitespace" do
      subscriber = Carriage::Subscriber.create!(email: "  Foo@Example.COM ")

      assert_equal "foo@example.com", subscriber.email
    end

    test "requires a unique email, case-insensitively" do
      Carriage::Subscriber.create!(email: "foo@example.com")
      duplicate = Carriage::Subscriber.new(email: "FOO@example.com")

      assert_not duplicate.valid?
    end

    test "mailkick subscribe/unsubscribe" do
      subscriber = Carriage::Subscriber.create!(email: "foo@example.com")

      subscriber.subscribe("weekly")
      assert subscriber.subscribed?("weekly")

      subscriber.unsubscribe("weekly")
      assert_not subscriber.subscribed?("weekly")
    end
  end
end

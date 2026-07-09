require "test_helper"

module Carriage
  class SegmentTest < ActiveSupport::TestCase
    setup do
      @list = Carriage::List.create!(name: "Weekly", fields_text: "plan")
    end

    test "requires a name unique within the list" do
      Carriage::Segment.create!(list: @list, name: "VIPs")
      duplicate = Carriage::Segment.new(list: @list, name: "VIPs")

      assert_not duplicate.valid?
    end

    test "conditions_text parses field/operator/value lines" do
      segment = Carriage::Segment.new(list: @list, name: "Pro plan", conditions_text: "plan equals pro\nemail contains example.com")

      assert_equal(
        [
          { "field" => "plan", "operator" => "equals", "value" => "pro" },
          { "field" => "email", "operator" => "contains", "value" => "example.com" }
        ],
        segment.conditions
      )
    end

    test "rejects a condition with an unknown field" do
      segment = Carriage::Segment.new(list: @list, name: "Bad", conditions_text: "nope equals pro")

      assert_not segment.valid?
    end

    test "rejects a condition with an invalid operator" do
      segment = Carriage::Segment.new(list: @list, name: "Bad", conditions_text: "plan startswith p")

      assert_not segment.valid?
    end

    test "is_set and not_set do not require a value" do
      segment = Carriage::Segment.new(list: @list, name: "Has plan", conditions_text: "plan is_set")

      assert segment.valid?
    end

    test "requires a value for equals" do
      segment = Carriage::Segment.new(list: @list, name: "Bad", conditions_text: "plan equals")

      assert_not segment.valid?
    end

    test "subscribers matches a custom field condition" do
      pro = Carriage::Subscriber.create!(email: "pro@example.com", custom_fields: { "plan" => "pro" })
      free = Carriage::Subscriber.create!(email: "free@example.com", custom_fields: { "plan" => "free" })
      Carriage::Subscription.create!(list: @list, subscriber: pro)
      Carriage::Subscription.create!(list: @list, subscriber: free)

      segment = Carriage::Segment.create!(list: @list, name: "Pro plan", conditions_text: "plan equals pro")

      assert_includes segment.subscribers, pro
      assert_not_includes segment.subscribers, free
    end

    test "any match_type unions conditions instead of intersecting" do
      pro = Carriage::Subscriber.create!(email: "pro@example.com", custom_fields: { "plan" => "pro" })
      vip = Carriage::Subscriber.create!(email: "vip@example.com", custom_fields: { "plan" => "vip" })
      free = Carriage::Subscriber.create!(email: "free@example.com", custom_fields: { "plan" => "free" })
      [ pro, vip, free ].each { |subscriber| Carriage::Subscription.create!(list: @list, subscriber: subscriber) }

      segment = Carriage::Segment.create!(list: @list, name: "Pro or VIP", match_type: "any", conditions_text: "plan equals pro\nplan equals vip")

      assert_includes segment.subscribers, pro
      assert_includes segment.subscribers, vip
      assert_not_includes segment.subscribers, free
    end

    test "active_subscribers excludes unsubscribed matches" do
      subscriber = Carriage::Subscriber.create!(email: "a@example.com", custom_fields: { "plan" => "pro" })
      subscription = Carriage::Subscription.create!(list: @list, subscriber: subscriber)

      segment = Carriage::Segment.create!(list: @list, name: "Pro plan", conditions_text: "plan equals pro")
      assert_includes segment.active_subscribers, subscriber

      subscription.unsubscribe!

      assert_not_includes segment.active_subscribers, subscriber
    end

    test "subscribers with no conditions matches every list member" do
      subscriber = Carriage::Subscriber.create!(email: "a@example.com")
      Carriage::Subscription.create!(list: @list, subscriber: subscriber)

      segment = Carriage::Segment.create!(list: @list, name: "Everyone")

      assert_includes segment.subscribers, subscriber
    end
  end
end

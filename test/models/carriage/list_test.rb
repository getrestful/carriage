require "test_helper"

module Carriage
  class ListTest < ActiveSupport::TestCase
    test "requires a unique name" do
      Carriage::List.create!(name: "Weekly")
      duplicate = Carriage::List.new(name: "Weekly")

      assert_not duplicate.valid?
    end

    test "active_subscribers excludes unsubscribed subscribers" do
      list = Carriage::List.create!(name: "Weekly")
      subscriber = Carriage::Subscriber.create!(email: "a@example.com")
      subscription = Carriage::Subscription.create!(list: list, subscriber: subscriber)

      assert_includes list.active_subscribers, subscriber

      subscription.unsubscribe!

      assert_not_includes list.active_subscribers, subscriber
    end

    test "fields_text parses one field name per line into the fields schema" do
      list = Carriage::List.new(name: "Weekly", fields_text: "company\nrole\n\n")

      assert_equal [ "company", "role" ], list.field_names
      assert_equal [ { "name" => "company", "type" => "string" }, { "name" => "role", "type" => "string" } ], list.fields
    end

    test "fields_text dedupes repeated field names" do
      list = Carriage::List.new(name: "Weekly", fields_text: "company\ncompany")

      assert_equal [ "company" ], list.field_names
    end

    test "rejects fields with an unsupported type" do
      list = Carriage::List.new(name: "Weekly", fields: [ { "name" => "company", "type" => "integer" } ])

      assert_not list.valid?
    end
  end
end

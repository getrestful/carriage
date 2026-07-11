require "test_helper"

module Carriage
  class ListTest < ActiveSupport::TestCase
    include ActionMailer::TestHelper

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

    test "add_subscriber creates a subscriber and an auto-confirmed subscription" do
      list = Carriage::List.create!(name: "Weekly", fields_text: "company")

      subscription = list.add_subscriber(email: "A@Example.com ", first_name: "Ada", custom_fields: { "company" => "Acme" })

      assert_equal "a@example.com", subscription.subscriber.email
      assert_equal "Ada", subscription.subscriber.first_name
      assert_equal({ "company" => "Acme" }, subscription.subscriber.custom_fields)
      assert subscription.confirmed?
    end

    test "add_subscriber ignores custom fields not in the list's schema" do
      list = Carriage::List.create!(name: "Weekly", fields_text: "company")

      subscription = list.add_subscriber(email: "a@example.com", custom_fields: { "company" => "Acme", "secret" => "nope" })

      assert_equal({ "company" => "Acme" }, subscription.subscriber.custom_fields)
    end

    test "add_subscriber is idempotent for an already-subscribed email" do
      list = Carriage::List.create!(name: "Weekly")

      first = list.add_subscriber(email: "a@example.com")
      second = list.add_subscriber(email: "a@example.com")

      assert_equal first, second
      assert_equal 1, list.subscriptions.count
    end

    test "add_subscriber with require_confirmation leaves the subscription pending and emails a confirmation link" do
      list = Carriage::List.create!(name: "Weekly")

      subscription = nil
      assert_enqueued_jobs 1, only: ActionMailer::MailDeliveryJob do
        subscription = list.add_subscriber(email: "a@example.com", require_confirmation: true)
      end

      assert_not subscription.confirmed?
    end

    test "add_subscriber raises with the invalid subscriber on a bad email" do
      list = Carriage::List.create!(name: "Weekly")

      error = assert_raises(ActiveRecord::RecordInvalid) { list.add_subscriber(email: "") }

      assert_kind_of Carriage::Subscriber, error.record
    end
  end
end

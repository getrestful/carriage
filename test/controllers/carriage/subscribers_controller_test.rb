require "test_helper"

module Carriage
  class SubscribersControllerTest < ActionDispatch::IntegrationTest
    test "create stores custom field values declared on the list's schema" do
      list = Carriage::List.create!(name: "Weekly", fields_text: "company")

      post "/carriage/lists/#{list.id}/subscribers", params: {
        subscriber: { email: "a@example.com", custom_fields: { "company" => "Acme", "ignored" => "x" } }
      }

      subscriber = Carriage::Subscriber.find_by(email: "a@example.com")
      assert_equal({ "company" => "Acme" }, subscriber.custom_fields)
    end

    test "update changes attributes and custom fields" do
      list = Carriage::List.create!(name: "Weekly", fields_text: "company")
      subscriber = Carriage::Subscriber.create!(email: "a@example.com", first_name: "Ann")
      Carriage::Subscription.create!(list: list, subscriber: subscriber)

      patch "/carriage/lists/#{list.id}/subscribers/#{subscriber.id}", params: {
        subscriber: { email: "a@example.com", first_name: "Annie", custom_fields: { "company" => "Acme" }, subscribed: "1" }
      }

      subscriber.reload
      assert_equal "Annie", subscriber.first_name
      assert_equal({ "company" => "Acme" }, subscriber.custom_fields)
    end

    test "update unsubscribes when the subscribed checkbox is unchecked" do
      list = Carriage::List.create!(name: "Weekly")
      subscriber = Carriage::Subscriber.create!(email: "a@example.com")
      subscription = Carriage::Subscription.create!(list: list, subscriber: subscriber)

      patch "/carriage/lists/#{list.id}/subscribers/#{subscriber.id}", params: {
        subscriber: { email: "a@example.com" }
      }

      assert subscription.reload.unsubscribed_at.present?
    end

    test "update resubscribes when the subscribed checkbox is checked" do
      list = Carriage::List.create!(name: "Weekly")
      subscriber = Carriage::Subscriber.create!(email: "a@example.com")
      subscription = Carriage::Subscription.create!(list: list, subscriber: subscriber)
      subscription.unsubscribe!

      patch "/carriage/lists/#{list.id}/subscribers/#{subscriber.id}", params: {
        subscriber: { email: "a@example.com", subscribed: "1" }
      }

      assert_nil subscription.reload.unsubscribed_at
    end
  end
end

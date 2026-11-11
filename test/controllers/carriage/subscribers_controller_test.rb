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

    test "resend_confirmation mails a pending subscriber again" do
      list = Carriage::List.create!(name: "Weekly")
      subscription = list.add_subscriber(email: "a@example.com", require_confirmation: true)
      path = "/carriage/lists/#{list.id}/subscribers/#{subscription.subscriber_id}/resend_confirmation"

      get "/carriage/lists/#{list.id}"
      assert_select "form[action='#{path}']"
      get "/carriage/lists/#{list.id}/subscribers"
      assert_select "form[action='#{path}']"

      assert_enqueued_emails 1 do
        post path
      end
      assert_redirected_to "/carriage/lists/#{list.id}"
    end

    test "resend_confirmation does not mail a confirmed subscriber" do
      list = Carriage::List.create!(name: "Weekly")
      subscription = list.add_subscriber(email: "a@example.com")

      assert_no_enqueued_emails do
        post "/carriage/lists/#{list.id}/subscribers/#{subscription.subscriber_id}/resend_confirmation"
      end
      assert_equal "Only pending subscribers can be sent a confirmation email.", flash[:alert]
    end
  end
end

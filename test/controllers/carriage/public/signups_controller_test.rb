require "test_helper"

module Carriage
  module Public
    class SignupsControllerTest < ActionDispatch::IntegrationTest
      include ActionMailer::TestHelper

      test "new renders the signup form for the list" do
        list = Carriage::List.create!(name: "Weekly")

        get "/c/lists/#{list.id}/signup"

        assert_response :success
      end

      test "create adds an unconfirmed subscription and sends a confirmation email" do
        list = Carriage::List.create!(name: "Weekly", fields_text: "company")

        assert_enqueued_jobs 1, only: ActionMailer::MailDeliveryJob do
          post "/c/lists/#{list.id}/signup", params: {
            subscriber: { email: "a@example.com", first_name: "Ann", custom_fields: { "company" => "Acme" } }
          }
        end

        assert_response :success
        subscriber = Carriage::Subscriber.find_by(email: "a@example.com")
        subscription = Carriage::Subscription.find_by(list: list, subscriber: subscriber)

        assert_equal({ "company" => "Acme" }, subscriber.custom_fields)
        assert_not subscription.confirmed?
        assert_not_includes list.active_subscribers, subscriber
      end
    end
  end
end

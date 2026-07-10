require "test_helper"

module Carriage
  module Public
    class ConfirmationsControllerTest < ActionDispatch::IntegrationTest
      test "show confirms a pending subscription" do
        list = Carriage::List.create!(name: "Weekly")
        subscriber = Carriage::Subscriber.create!(email: "a@example.com")
        subscription = Carriage::Subscription.create!(list: list, subscriber: subscriber, require_confirmation: true)
        token = subscription.generate_token_for(:confirm_subscription)

        get Carriage::Public::Engine.routes.url_helpers.confirm_subscription_path(token: token)

        assert_response :success
        assert subscription.reload.confirmed?
        assert_includes list.active_subscribers, subscriber
      end

      test "show renders an invalid state for an unknown token" do
        get "/c/confirm/does-not-exist"

        assert_response :success
      end
    end
  end
end

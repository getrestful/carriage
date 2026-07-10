require "test_helper"

module Carriage
  class ConfirmationMailerTest < ActionMailer::TestCase
    setup do
      @list = Carriage::List.create!(name: "Weekly")
      @subscriber = Carriage::Subscriber.create!(email: "a@example.com")
      @subscription = Carriage::Subscription.create!(list: @list, subscriber: @subscriber, require_confirmation: true)
    end

    test "renders subject, recipient, and a working confirmation link" do
      mail = Carriage::ConfirmationMailer.confirm_email(@subscription)

      assert_equal [ "a@example.com" ], mail.to
      assert_match "Weekly", mail.subject

      body = mail.html_part.body.to_s
      assert_match %r{/c/confirm/}, body
      token = body[%r{/c/confirm/([^"]+)}, 1]
      assert_equal @subscription, Carriage::Subscription.find_by_token_for(:confirm_subscription, token)
    end
  end
end

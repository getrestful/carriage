require "test_helper"

module Carriage
  class DeliverTestEmailJobTest < ActiveJob::TestCase
    include ActionMailer::TestHelper

    test "delivers a test email and marks the delivery sent, excluded from real stats" do
      list = Carriage::List.create!(name: "Weekly")
      campaign = Carriage::Campaign.create!(list: list, name: "Launch", subject: "Hi", body_html: "<p>hi</p>")

      assert_emails 1 do
        Carriage::DeliverTestEmailJob.perform_now(campaign.id, "tester@example.com")
      end

      delivery = campaign.deliveries.find_by(subscriber: Carriage::Subscriber.find_by(email: "tester@example.com"))
      assert delivery.sent?
      assert delivery.is_test?
      assert_equal 0, campaign.deliveries.real.count
    end
  end
end

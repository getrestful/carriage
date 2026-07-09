require "test_helper"

module Carriage
  class DeliverSubscriberJobTest < ActiveJob::TestCase
    include ActionMailer::TestHelper

    test "delivers the mail and marks the delivery sent" do
      list = Carriage::List.create!(name: "Weekly")
      campaign = Carriage::Campaign.create!(list: list, name: "Launch", subject: "Hi", body_html: "<p>hi</p>")
      subscriber = Carriage::Subscriber.create!(email: "a@example.com")
      delivery = Carriage::Delivery.create!(campaign: campaign, subscriber: subscriber)

      assert_emails 1 do
        Carriage::DeliverSubscriberJob.perform_now(delivery.id)
      end

      assert delivery.reload.sent?
      assert delivery.sent_at.present?
    end

    test "marks the delivery failed and schedules a retry on mailer error" do
      list = Carriage::List.create!(name: "Weekly")
      campaign = Carriage::Campaign.create!(list: list, name: "Launch", subject: "Hi", body_html: "<p>hi</p>")
      subscriber = Carriage::Subscriber.create!(email: "a@example.com")
      delivery = Carriage::Delivery.create!(campaign: campaign, subscriber: subscriber)

      Carriage::CampaignMailer.define_singleton_method(:campaign_email) { |_delivery| raise "boom" }

      assert_enqueued_with(job: Carriage::DeliverSubscriberJob) do
        Carriage::DeliverSubscriberJob.perform_now(delivery.id)
      end

      assert delivery.reload.failed?
      assert_equal "boom", delivery.error_message
    ensure
      Carriage::CampaignMailer.singleton_class.send(:remove_method, :campaign_email)
    end
  end
end

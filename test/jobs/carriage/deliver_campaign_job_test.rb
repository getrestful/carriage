require "test_helper"

module Carriage
  class DeliverCampaignJobTest < ActiveJob::TestCase
    test "enqueues a delivery job per active subscriber and marks campaign sent" do
      list = Carriage::List.create!(name: "Weekly")
      subscribed = Carriage::Subscriber.create!(email: "sub@example.com")
      unsubscribed = Carriage::Subscriber.create!(email: "unsub@example.com")
      Carriage::Subscription.create!(list: list, subscriber: subscribed)
      Carriage::Subscription.create!(list: list, subscriber: unsubscribed).unsubscribe!

      campaign = Carriage::Campaign.create!(list: list, name: "Launch", subject: "Hi", body_html: "<p>hi</p>")

      assert_enqueued_with(job: Carriage::DeliverSubscriberJob) do
        Carriage::DeliverCampaignJob.perform_now(campaign.id)
      end

      assert_equal 1, campaign.deliveries.real.count
      assert_equal subscribed, campaign.deliveries.real.first.subscriber
      assert campaign.reload.sent?
    end
  end
end

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

    test "only delivers to a campaign's segment when one is set" do
      list = Carriage::List.create!(name: "Weekly", fields_text: "plan")
      pro = Carriage::Subscriber.create!(email: "pro@example.com", custom_fields: { "plan" => "pro" })
      free = Carriage::Subscriber.create!(email: "free@example.com", custom_fields: { "plan" => "free" })
      Carriage::Subscription.create!(list: list, subscriber: pro)
      Carriage::Subscription.create!(list: list, subscriber: free)
      segment = Carriage::Segment.create!(list: list, name: "Pro plan", conditions_text: "plan equals pro")

      campaign = Carriage::Campaign.create!(list: list, segment: segment, name: "Launch", subject: "Hi", body_html: "<p>hi</p>")

      Carriage::DeliverCampaignJob.perform_now(campaign.id)

      assert_equal 1, campaign.deliveries.real.count
      assert_equal pro, campaign.deliveries.real.first.subscriber
    end
  end
end

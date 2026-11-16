require "test_helper"

module Carriage
  class CampaignStatsTest < ActiveSupport::TestCase
    test "computes sent, opens, and click stats excluding test sends" do
      list = Carriage::List.create!(name: "Weekly")
      campaign = Carriage::Campaign.create!(list: list, name: "Launch", subject: "Hi")

      s1 = Carriage::Subscriber.create!(email: "a@example.com")
      s2 = Carriage::Subscriber.create!(email: "b@example.com")
      d1 = Carriage::Delivery.create!(campaign: campaign, subscriber: s1, state: :sent)
      d2 = Carriage::Delivery.create!(campaign: campaign, subscriber: s2, state: :sent)
      Carriage::Delivery.create!(campaign: campaign, subscriber: Carriage::Subscriber.create!(email: "test@example.com"), state: :sent, is_test: true)

      d1.register_open!
      click = d1.clicks.create!(url: "https://example.com")
      click.register_click!
      click.register_click!

      stats = Carriage::CampaignStats.new(campaign)

      assert_equal 2, stats.sent_count
      assert_equal 1, stats.opens_count
      assert_equal 50.0, stats.open_rate
      assert_equal 1, stats.clicked_deliveries_count
      assert_equal 2, stats.total_clicks_count
    end

    test "counts retrying and failed deliveries and exposes the latest error" do
      list = Carriage::List.create!(name: "Weekly")
      campaign = Carriage::Campaign.create!(list: list, name: "Launch", subject: "Hi")
      subscriber = ->(email) { Carriage::Subscriber.create!(email: email) }

      Carriage::Delivery.create!(campaign: campaign, subscriber: subscriber.("a@example.com"), state: :sent)
      Carriage::Delivery.create!(campaign: campaign, subscriber: subscriber.("b@example.com"), state: :failed, error_message: "old", updated_at: 1.hour.ago)
      Carriage::Delivery.create!(campaign: campaign, subscriber: subscriber.("c@example.com"), state: :retrying, error_message: "connection refused")
      Carriage::Delivery.create!(campaign: campaign, subscriber: subscriber.("d@example.com"), state: :retrying, error_message: "older", updated_at: 2.hours.ago)

      stats = Carriage::CampaignStats.new(campaign)

      assert_equal 2, stats.retrying_count
      assert_equal 1, stats.failed_count
      assert_equal "connection refused", stats.latest_delivery_error
      assert_equal 1, stats.sent_count
    end
  end
end

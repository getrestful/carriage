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
  end
end

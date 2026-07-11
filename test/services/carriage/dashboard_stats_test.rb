require "test_helper"

module Carriage
  class DashboardStatsTest < ActiveSupport::TestCase
    test "aggregates audience, sends, opens, and clicks across all campaigns, excluding test sends" do
      list = Carriage::List.create!(name: "Weekly")
      other_list = Carriage::List.create!(name: "Monthly")

      s1 = Carriage::Subscriber.create!(email: "a@example.com")
      s2 = Carriage::Subscriber.create!(email: "b@example.com")
      unsubscribed = Carriage::Subscriber.create!(email: "c@example.com")

      Carriage::Subscription.create!(list: list, subscriber: s1)
      # s2 is on both lists — the audience count should still only count them once.
      Carriage::Subscription.create!(list: list, subscriber: s2)
      Carriage::Subscription.create!(list: other_list, subscriber: s2)
      unsubscribed_subscription = Carriage::Subscription.create!(list: list, subscriber: unsubscribed)
      unsubscribed_subscription.unsubscribe!

      campaign = Carriage::Campaign.create!(list: list, name: "Launch", subject: "Hi", status: :sent)
      other_campaign = Carriage::Campaign.create!(list: other_list, name: "Roundup", subject: "Hey", status: :sent)
      Carriage::Campaign.create!(list: list, name: "Draft", subject: "Wip")

      d1 = Carriage::Delivery.create!(campaign: campaign, subscriber: s1, state: :sent)
      d2 = Carriage::Delivery.create!(campaign: other_campaign, subscriber: s2, state: :sent)
      Carriage::Delivery.create!(campaign: campaign, subscriber: Carriage::Subscriber.create!(email: "test@example.com"), state: :sent, is_test: true)

      d1.register_open!
      click = d1.clicks.create!(url: "https://example.com")
      click.register_click!

      stats = Carriage::DashboardStats.new

      assert_equal 2, stats.audience_count
      assert_equal 2, stats.campaigns_sent_count
      assert_equal 2, stats.emails_sent_count
      assert_equal 50.0, stats.open_rate
      assert_equal 50.0, stats.click_through_rate
    end

    test "rates are zero when nothing has been sent yet" do
      stats = Carriage::DashboardStats.new

      assert_equal 0, stats.emails_sent_count
      assert_equal 0.0, stats.open_rate
      assert_equal 0.0, stats.click_through_rate
    end
  end
end

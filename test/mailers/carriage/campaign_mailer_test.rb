require "test_helper"

module Carriage
  class CampaignMailerTest < ActionMailer::TestCase
    setup do
      list = Carriage::List.create!(name: "Weekly")
      @campaign = Carriage::Campaign.create!(
        list: list, name: "Launch", subject: "Hello there",
        heading: "Welcome", body_html: "<p>Hi <a href=\"https://example.com\">link</a></p>",
        cta_label: "Go", cta_url: "https://example.com/go"
      )
      @subscriber = Carriage::Subscriber.create!(email: "a@example.com")
      @delivery = Carriage::Delivery.create!(campaign: @campaign, subscriber: @subscriber)
    end

    test "renders subject, recipient, and compiled MJML body" do
      mail = Carriage::CampaignMailer.campaign_email(@delivery)

      assert_equal [ "a@example.com" ], mail.to
      assert_equal "Hello there", mail.subject
      assert_match "Welcome", mail.body.to_s
    end

    test "rewrites links for click tracking and appends open pixel" do
      mail = Carriage::CampaignMailer.campaign_email(@delivery)
      body = mail.body.to_s

      assert_match %r{/c/c/}, body
      assert_match %r{/c/o/#{@delivery.token}}, body
      assert_no_match %r{href="https://example.com/go"}, body
    end

    test "delivering the mail creates click records" do
      Carriage::CampaignMailer.campaign_email(@delivery).deliver_now

      assert_equal 2, @delivery.clicks.count
    end
  end
end

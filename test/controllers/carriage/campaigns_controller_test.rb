require "test_helper"

module Carriage
  class CampaignsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @list = Carriage::List.create!(name: "Weekly")
      @campaign = Carriage::Campaign.create!(
        list: @list, name: "Launch", subject: "Hi",
        body_html: "<p>Hi <a href=\"https://example.com\">link</a></p>"
      )
    end

    test "shows stats for a campaign" do
      get "/carriage/campaigns/#{@campaign.id}"

      assert_response :success
      assert_match "Sent", response.body
    end

    test "preview renders compiled MJML html" do
      get "/carriage/campaigns/#{@campaign.id}/preview"

      assert_response :success
      assert_match "</html>", response.body
    end

    test "send_test enqueues a test email job for a valid address" do
      assert_enqueued_with(job: Carriage::DeliverTestEmailJob, args: [ @campaign.id, "tester@example.com" ]) do
        post "/carriage/campaigns/#{@campaign.id}/send_test", params: { test_email: "tester@example.com" }
      end

      assert_redirected_to "/carriage/campaigns/#{@campaign.id}"
    end

    test "send_test rejects an invalid address" do
      assert_no_enqueued_jobs do
        post "/carriage/campaigns/#{@campaign.id}/send_test", params: { test_email: "not-an-email" }
      end
    end

    test "schedule sets scheduled status" do
      post "/carriage/campaigns/#{@campaign.id}/schedule", params: { scheduled_at: 1.hour.from_now.iso8601 }

      assert @campaign.reload.scheduled?
    end

    test "send_now enqueues the campaign delivery job" do
      assert_enqueued_with(job: Carriage::DeliverCampaignJob, args: [ @campaign.id ]) do
        post "/carriage/campaigns/#{@campaign.id}/send_now"
      end
    end

    test "duplicate creates a new draft campaign with copied fields" do
      assert_difference "Carriage::Campaign.count", 1 do
        post "/carriage/campaigns/#{@campaign.id}/duplicate"
      end

      copy = Carriage::Campaign.last
      assert_redirected_to "/carriage/campaigns/#{copy.id}/edit"
      assert_equal "Launch (Copy)", copy.name
      assert_equal @campaign.subject, copy.subject
      assert_equal @campaign.body_html.to_s, copy.body_html.to_s
      assert copy.draft?
    end
  end
end

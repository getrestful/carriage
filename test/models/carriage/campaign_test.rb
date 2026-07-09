require "test_helper"

module Carriage
  class CampaignTest < ActiveSupport::TestCase
    setup do
      @list = Carriage::List.create!(name: "Weekly")
    end

    test "requires name and subject" do
      campaign = Carriage::Campaign.new(list: @list)

      assert_not campaign.valid?
      assert_includes campaign.errors.attribute_names, :name
      assert_includes campaign.errors.attribute_names, :subject
    end

    test "defaults to draft status" do
      campaign = Carriage::Campaign.create!(list: @list, name: "Launch", subject: "Hi")

      assert campaign.draft?
    end

    test "schedule! sets status and scheduled_at" do
      campaign = Carriage::Campaign.create!(list: @list, name: "Launch", subject: "Hi")
      time = 1.hour.from_now

      campaign.schedule!(time)

      assert campaign.scheduled?
      assert_in_delta time.to_i, campaign.scheduled_at.to_i, 1
    end
  end
end

module Carriage
  class DeliverTestEmailJob < ApplicationJob
    queue_as :default

    def perform(campaign_id, test_email)
      campaign = Carriage::Campaign.find(campaign_id)
      subscriber = Carriage::Subscriber.find_or_create_by!(email: test_email)
      delivery = Carriage::Delivery.find_or_create_by!(campaign: campaign, subscriber: subscriber) do |d|
        d.is_test = true
      end

      Carriage::CampaignMailer.campaign_email(delivery).deliver_now
      delivery.update!(state: :sent, sent_at: Time.current)
    end
  end
end

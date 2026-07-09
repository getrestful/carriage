module Carriage
  class DeliverCampaignJob < ApplicationJob
    queue_as :default

    def perform(campaign_id)
      campaign = Carriage::Campaign.find(campaign_id)
      return if campaign.sent? || campaign.sending?

      campaign.update!(status: :sending)

      campaign.list.active_subscribers.find_each do |subscriber|
        delivery = Carriage::Delivery.find_or_create_by!(campaign: campaign, subscriber: subscriber)
        Carriage::DeliverSubscriberJob.perform_later(delivery.id)
      end

      campaign.update!(status: :sent, sent_at: Time.current)
    end
  end
end

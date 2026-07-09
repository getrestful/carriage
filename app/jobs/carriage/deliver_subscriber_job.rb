module Carriage
  class DeliverSubscriberJob < ApplicationJob
    queue_as :default
    retry_on StandardError, wait: :polynomially_longer, attempts: 3

    def perform(delivery_id)
      delivery = Carriage::Delivery.find(delivery_id)
      return if delivery.sent?

      Carriage::CampaignMailer.campaign_email(delivery).deliver_now
      delivery.update!(state: :sent, sent_at: Time.current)
    rescue => e
      delivery.update!(state: :failed, error_message: e.message)
      raise
    end
  end
end

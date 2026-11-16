module Carriage
  class DeliverSubscriberJob < ApplicationJob
    queue_as :default

    # The block runs once the attempts are used up.
    retry_on StandardError, wait: :polynomially_longer, attempts: Carriage.delivery_attempts do |job, error|
      Carriage::Delivery.where(id: job.arguments.first).update_all(state: "failed", updated_at: Time.current)
      raise error
    end

    def perform(delivery_id)
      delivery = Carriage::Delivery.find(delivery_id)
      return if delivery.sent?

      Carriage::CampaignMailer.campaign_email(delivery).deliver_now
      delivery.update!(state: :sent, sent_at: Time.current)
    rescue => e
      delivery&.update!(state: :retrying, error_message: e.message)
      raise
    end
  end
end

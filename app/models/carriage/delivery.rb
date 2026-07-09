require "securerandom"

module Carriage
  class Delivery < ApplicationRecord
    belongs_to :campaign, class_name: "Carriage::Campaign"
    belongs_to :subscriber, class_name: "Carriage::Subscriber"
    has_many :clicks, class_name: "Carriage::Click", dependent: :destroy

    enum :state, { pending: "pending", sent: "sent", failed: "failed" }, default: "pending"

    scope :real, -> { where(is_test: false) }

    before_validation :ensure_token, on: :create

    def subscription
      Carriage::Subscription.find_by(list_id: campaign.list_id, subscriber_id: subscriber_id)
    end

    def register_open!
      update!(opened_at: Time.current) if opened_at.nil?
    end

    private

    def ensure_token
      self.token ||= SecureRandom.urlsafe_base64(24)
    end
  end
end

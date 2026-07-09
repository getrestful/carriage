require "securerandom"

module Carriage
  class Click < ApplicationRecord
    belongs_to :delivery, class_name: "Carriage::Delivery"

    validates :url, presence: true

    before_validation :ensure_token, on: :create

    def register_click!
      update!(click_count: click_count + 1, clicked_at: clicked_at || Time.current)
    end

    private

    def ensure_token
      self.token ||= SecureRandom.urlsafe_base64(24)
    end
  end
end

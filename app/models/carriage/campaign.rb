module Carriage
  class Campaign < ApplicationRecord
    belongs_to :list, class_name: "Carriage::List"
    has_many :deliveries, class_name: "Carriage::Delivery", dependent: :destroy

    enum :status, { draft: "draft", scheduled: "scheduled", sending: "sending", sent: "sent" }, default: "draft"

    validates :name, presence: true
    validates :subject, presence: true

    def schedule!(scheduled_at)
      update!(status: :scheduled, scheduled_at: scheduled_at)
    end

    def duplicate
      Carriage::Campaign.create!(
        list_id: list_id, name: "#{name} (Copy)", subject: subject, preheader: preheader,
        heading: heading, body_html: body_html, cta_label: cta_label, cta_url: cta_url, footer_text: footer_text
      )
    end
  end
end

module Carriage
  class Campaign < ApplicationRecord
    belongs_to :list, class_name: "Carriage::List"
    belongs_to :segment, class_name: "Carriage::Segment", optional: true
    has_many :deliveries, class_name: "Carriage::Delivery", dependent: :destroy

    enum :status, { draft: "draft", scheduled: "scheduled", sending: "sending", sent: "sent" }, default: "draft"

    validates :name, presence: true
    validates :subject, presence: true
    validate :segment_belongs_to_list

    def schedule!(scheduled_at)
      update!(status: :scheduled, scheduled_at: scheduled_at)
    end

    def recipients
      (segment || list).active_subscribers
    end

    def duplicate
      Carriage::Campaign.create!(
        list_id: list_id, segment_id: segment_id, name: "#{name} (Copy)", subject: subject, preheader: preheader,
        heading: heading, body_html: body_html, cta_label: cta_label, cta_url: cta_url, footer_text: footer_text
      )
    end

    private

    def segment_belongs_to_list
      errors.add(:segment, "must belong to the campaign's list") if segment && segment.list_id != list_id
    end
  end
end

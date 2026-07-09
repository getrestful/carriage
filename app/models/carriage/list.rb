module Carriage
  class List < ApplicationRecord
    FIELD_TYPES = %w[string].freeze

    has_many :subscriptions, class_name: "Carriage::Subscription", dependent: :destroy
    has_many :subscribers, through: :subscriptions, class_name: "Carriage::Subscriber"
    has_many :campaigns, class_name: "Carriage::Campaign", dependent: :destroy
    has_many :segments, class_name: "Carriage::Segment", dependent: :destroy

    validates :name, presence: true, uniqueness: true
    validate :fields_are_valid

    def active_subscribers
      subscribers.merge(Carriage::Subscription.active)
    end

    def field_names
      fields.map { |field| field["name"] }
    end

    # One field name per line, backing the plain-text schema editor on the list form.
    def fields_text
      field_names.join("\n")
    end

    def fields_text=(text)
      self.fields = text.to_s.each_line.map(&:strip).reject(&:blank?).uniq.map { |name| { "name" => name, "type" => "string" } }
    end

    private

    def fields_are_valid
      names = field_names
      errors.add(:fields, "must have unique names") if names.uniq.length != names.length

      fields.each do |field|
        errors.add(:fields, "type must be one of #{FIELD_TYPES.join(', ')}") unless FIELD_TYPES.include?(field["type"])
      end
    end
  end
end

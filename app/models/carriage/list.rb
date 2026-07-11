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

    # Consolidates the "find-or-create subscriber, then join to this list" flow that the
    # CSV importer, the admin "add subscriber" form, and the public signup form each used to
    # reimplement independently (and had drifted on: only the signup form set
    # require_confirmation). Idempotent — calling it twice for the same email returns the
    # existing subscription rather than raising, so host apps can call it unconditionally
    # without checking membership first. Raises ActiveRecord::RecordInvalid (with the unsaved
    # Subscriber as e.record) if the email is missing/invalid; callers that need to redisplay
    # a form with errors should rescue and render from e.record.
    def add_subscriber(email:, first_name: nil, last_name: nil, custom_fields: {}, require_confirmation: false)
      subscriber = Carriage::Subscriber.find_or_initialize_by(email: email.to_s.strip.downcase)
      subscriber.first_name = first_name if first_name
      subscriber.last_name = last_name if last_name
      subscriber.custom_fields = subscriber.custom_fields.merge(custom_fields.slice(*field_names))
      subscriber.save!

      subscriptions.find_or_create_by(subscriber: subscriber) do |subscription|
        subscription.require_confirmation = require_confirmation
      end
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

module Carriage
  class Segment < ApplicationRecord
    OPERATORS = %w[equals contains is_set not_set before after].freeze
    OPERATORS_REQUIRING_VALUE = %w[equals contains before after].freeze
    CORE_FIELDS = %w[email status created_at].freeze

    belongs_to :list, class_name: "Carriage::List"
    has_many :campaigns, class_name: "Carriage::Campaign", dependent: :nullify

    enum :match_type, { all: "all", any: "any" }, default: "all", scopes: false

    validates :name, presence: true, uniqueness: { scope: :list_id }
    validate :conditions_are_valid

    # One condition per line: "<field> <operator> [value]", backing the plain-text condition editor.
    def conditions_text
      conditions.map { |condition| [ condition["field"], condition["operator"], condition["value"] ].compact.join(" ") }.join("\n")
    end

    def conditions_text=(text)
      self.conditions = text.to_s.each_line.map(&:strip).reject(&:blank?).map do |line|
        field, operator, value = line.split(/\s+/, 3)
        { "field" => field, "operator" => operator, "value" => value }.compact
      end
    end

    def subscribers
      Carriage::SegmentQuery.new(self).call
    end

    def active_subscribers
      subscribers.merge(Carriage::Subscription.active)
    end

    private

    def conditions_are_valid
      conditions.each do |condition|
        field = condition["field"]
        operator = condition["operator"]

        if operator.blank? || !OPERATORS.include?(operator)
          errors.add(:conditions, "operator '#{operator}' is invalid")
        end

        unless CORE_FIELDS.include?(field) || list&.field_names&.include?(field)
          errors.add(:conditions, "field '#{field}' is not a known field for this list")
        end

        if OPERATORS_REQUIRING_VALUE.include?(operator) && condition["value"].blank?
          errors.add(:conditions, "'#{field} #{operator}' requires a value")
        end
      end
    end
  end
end

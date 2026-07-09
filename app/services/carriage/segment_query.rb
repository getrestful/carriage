module Carriage
  # Evaluates a Segment's conditions against its list's subscribers (any status - callers that
  # need send-eligible recipients should use Segment#active_subscribers instead). Each condition
  # is resolved to a set of subscriber ids independently, then combined via intersection (match_type
  # "all") or union (match_type "any"), since mixing AND/OR joins/json-extraction into a single SQL
  # query across subscribers, subscriptions and custom_fields isn't worth the complexity at this scale.
  class SegmentQuery
    def initialize(segment)
      @segment = segment
      @list = segment.list
    end

    def call
      conditions = @segment.conditions
      return @list.subscribers if conditions.empty?

      id_sets = conditions.map { |condition| matching_ids(condition) }
      combined_ids = @segment.any? ? id_sets.reduce(:|) : id_sets.reduce(:&)

      @list.subscribers.where(id: combined_ids)
    end

    private

    def matching_ids(condition)
      field, operator, value = condition.values_at("field", "operator", "value")

      scope =
        case field
        when "email"
          text_operator(@list.subscribers, "carriage_subscribers.email", operator, value)
        when "status"
          status_operator(@list.subscribers, value)
        when "created_at"
          date_operator(@list.subscribers, "carriage_subscribers.created_at", operator, value)
        else
          custom_field_operator(@list.subscribers, field, operator, value)
        end

      scope.pluck(:id)
    end

    def text_operator(scope, column, operator, value)
      case operator
      when "equals" then scope.where("#{column} = ?", value)
      when "contains" then scope.where("#{column} LIKE ?", "%#{Carriage::Subscriber.sanitize_sql_like(value)}%")
      else scope.none
      end
    end

    def date_operator(scope, column, operator, value)
      date = Date.parse(value) rescue nil
      return scope.none unless date

      case operator
      when "before" then scope.where("#{column} < ?", date)
      when "after" then scope.where("#{column} > ?", date)
      else scope.none
      end
    end

    def status_operator(scope, value)
      if value == "unsubscribed"
        scope.where.not(carriage_subscriptions: { unsubscribed_at: nil })
      else
        scope.where(carriage_subscriptions: { unsubscribed_at: nil })
      end
    end

    def custom_field_operator(scope, field, operator, value)
      extract_sql = "json_extract(carriage_subscribers.custom_fields, ?)"
      json_path = "$.#{field}"

      case operator
      when "equals" then scope.where("#{extract_sql} = ?", json_path, value)
      when "contains" then scope.where("#{extract_sql} LIKE ?", json_path, "%#{Carriage::Subscriber.sanitize_sql_like(value)}%")
      when "is_set" then scope.where.not("#{extract_sql} IS NULL", json_path)
      when "not_set" then scope.where("#{extract_sql} IS NULL", json_path)
      else scope.none
      end
    end
  end
end

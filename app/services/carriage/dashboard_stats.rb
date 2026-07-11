module Carriage
  class DashboardStats
    # Distinct subscribers with at least one confirmed, non-unsubscribed subscription —
    # mirrors List#active_subscribers/Segment#active_subscribers but across every list, so
    # someone on two lists only counts once.
    def audience_count
      Carriage::Subscriber.joins(:subscriptions).merge(Carriage::Subscription.active).distinct.count
    end

    def campaigns_sent_count
      Carriage::Campaign.sent.count
    end

    def emails_sent_count
      deliveries.sent.count
    end

    def open_rate
      rate(deliveries.where.not(opened_at: nil).count)
    end

    def click_through_rate
      rate(deliveries.joins(:clicks).where.not(carriage_clicks: { clicked_at: nil }).distinct.count)
    end

    private

    # Same Delivery.real exclusion CampaignStats uses, so test sends never inflate these
    # numbers either.
    def deliveries
      Carriage::Delivery.real
    end

    def rate(numerator)
      return 0.0 if emails_sent_count.zero?

      (numerator.to_f / emails_sent_count * 100).round(1)
    end
  end
end

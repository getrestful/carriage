module Carriage
  class CampaignStats
    def initialize(campaign)
      @campaign = campaign
    end

    def sent_count
      deliveries.sent.count
    end

    def opens_count
      deliveries.where.not(opened_at: nil).count
    end

    def clicked_deliveries_count
      deliveries.joins(:clicks).where.not(carriage_clicks: { clicked_at: nil }).distinct.count
    end

    def total_clicks_count
      Carriage::Click.where(delivery_id: deliveries.select(:id)).sum(:click_count)
    end

    def open_rate
      rate(opens_count)
    end

    def click_through_rate
      rate(clicked_deliveries_count)
    end

    private

    def deliveries
      @campaign.deliveries.real
    end

    def rate(numerator)
      return 0.0 if sent_count.zero?

      (numerator.to_f / sent_count * 100).round(1)
    end
  end
end

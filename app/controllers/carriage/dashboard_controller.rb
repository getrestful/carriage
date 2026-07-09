module Carriage
  class DashboardController < ApplicationController
    def index
      @lists = Carriage::List.order(:name)
      @recent_campaigns = Carriage::Campaign.order(created_at: :desc).limit(10)
    end
  end
end

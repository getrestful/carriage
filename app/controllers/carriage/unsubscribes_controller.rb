module Carriage
  # Public, unauthenticated endpoint linked from campaign email footers.
  class UnsubscribesController < ActionController::Base
    skip_forgery_protection

    def show
      @delivery = Carriage::Delivery.find_by(token: params[:token])
      @delivery&.subscription&.unsubscribe!
    end
  end
end

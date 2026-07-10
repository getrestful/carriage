module Carriage
  module Public
    class UnsubscribesController < ApplicationController
      def show
        @delivery = Carriage::Delivery.find_by(token: params[:token])
        @delivery&.subscription&.unsubscribe!
      end
    end
  end
end

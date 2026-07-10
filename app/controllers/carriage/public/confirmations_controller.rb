module Carriage
  module Public
    class ConfirmationsController < ApplicationController
      def show
        @subscription = Carriage::Subscription.find_by_token_for(:confirm_subscription, params[:token])
        @subscription&.confirm!
      end
    end
  end
end

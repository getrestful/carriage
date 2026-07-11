module Carriage
  module Public
    class SignupsController < ApplicationController
      before_action :set_list

      def new
        @subscriber = Carriage::Subscriber.new
      end

      def create
        subscription = @list.add_subscriber(
          email: params.dig(:subscriber, :email),
          first_name: params.dig(:subscriber, :first_name),
          last_name: params.dig(:subscriber, :last_name),
          custom_fields: custom_field_params,
          require_confirmation: true
        )
        @subscriber = subscription.subscriber
        render :pending
      rescue ActiveRecord::RecordInvalid => e
        @subscriber = e.record
        render :new, status: :unprocessable_entity
      end

      private

      def set_list
        @list = Carriage::List.find(params[:list_id])
      end

      def custom_field_params
        params.fetch(:subscriber, {}).fetch(:custom_fields, {}).slice(*@list.field_names).permit!.to_h
      end
    end
  end
end

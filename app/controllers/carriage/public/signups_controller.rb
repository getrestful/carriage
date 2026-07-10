module Carriage
  module Public
    class SignupsController < ApplicationController
      before_action :set_list

      def new
        @subscriber = Carriage::Subscriber.new
      end

      def create
        @subscriber = Carriage::Subscriber.find_or_initialize_by(email: params.dig(:subscriber, :email).to_s.strip.downcase)
        @subscriber.first_name = params.dig(:subscriber, :first_name)
        @subscriber.last_name = params.dig(:subscriber, :last_name)
        @subscriber.custom_fields = @subscriber.custom_fields.merge(custom_field_params)

        if @subscriber.save
          Carriage::Subscription.find_or_create_by!(list: @list, subscriber: @subscriber) do |subscription|
            subscription.require_confirmation = true
          end
          render :pending
        else
          render :new, status: :unprocessable_entity
        end
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

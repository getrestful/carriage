module Carriage
  class SubscribersController < ApplicationController
    before_action :set_list

    def index
      @subscribers = @list.subscribers.order(:email)
    end

    def new
      @subscriber = Carriage::Subscriber.new
    end

    def create
      @subscriber = Carriage::Subscriber.find_or_initialize_by(email: params[:subscriber][:email].to_s.strip.downcase)
      @subscriber.first_name = params[:subscriber][:first_name]
      @subscriber.last_name = params[:subscriber][:last_name]
      @subscriber.custom_fields = @subscriber.custom_fields.merge(custom_field_params)

      if @subscriber.save
        Carriage::Subscription.find_or_create_by!(list: @list, subscriber: @subscriber)
        redirect_to list_path(@list), notice: "Subscriber added."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      subscriber = @list.subscribers.find(params[:id])
      Carriage::Subscription.find_by(list: @list, subscriber: subscriber)&.unsubscribe!
      redirect_to list_path(@list), notice: "Subscriber removed."
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

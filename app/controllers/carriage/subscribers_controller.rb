module Carriage
  class SubscribersController < ApplicationController
    before_action :set_list

    def index
      @subscriptions = @list.subscriptions.includes(:subscriber).order("carriage_subscribers.email")
    end

    def new
      @subscriber = Carriage::Subscriber.new
    end

    def create
      @subscriber = Carriage::Subscriber.find_or_initialize_by(email: params[:subscriber][:email].to_s.strip.downcase)
      assign_subscriber_attributes

      if @subscriber.save
        Carriage::Subscription.find_or_create_by!(list: @list, subscriber: @subscriber)
        redirect_to list_path(@list), notice: "Subscriber added."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @subscriber = @list.subscribers.find(params[:id])
      @subscription = subscription_for(@subscriber)
    end

    def update
      @subscriber = @list.subscribers.find(params[:id])
      @subscription = subscription_for(@subscriber)
      assign_subscriber_attributes

      if @subscriber.save
        if params[:subscriber][:subscribed] == "1"
          @subscription.resubscribe! if @subscription.unsubscribed_at.present?
        else
          @subscription.unsubscribe! if @subscription.unsubscribed_at.nil?
        end
        redirect_to list_path(@list), notice: "Subscriber updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      subscriber = @list.subscribers.find(params[:id])
      subscription_for(subscriber)&.unsubscribe!
      redirect_to list_path(@list), notice: "Subscriber removed."
    end

    private

    def set_list
      @list = Carriage::List.find(params[:list_id])
    end

    def subscription_for(subscriber)
      Carriage::Subscription.find_by(list: @list, subscriber: subscriber)
    end

    def assign_subscriber_attributes
      @subscriber.email = params[:subscriber][:email].to_s.strip.downcase
      @subscriber.first_name = params[:subscriber][:first_name]
      @subscriber.last_name = params[:subscriber][:last_name]
      @subscriber.custom_fields = @subscriber.custom_fields.merge(custom_field_params)
    end

    def custom_field_params
      params.fetch(:subscriber, {}).fetch(:custom_fields, {}).slice(*@list.field_names).permit!.to_h
    end
  end
end

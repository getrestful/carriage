require "test_helper"

module Carriage
  class DeliveryTest < ActiveSupport::TestCase
    setup do
      list = Carriage::List.create!(name: "Weekly")
      @campaign = Carriage::Campaign.create!(list: list, name: "Launch", subject: "Hi")
      @subscriber = Carriage::Subscriber.create!(email: "a@example.com")
    end

    test "generates a unique token on create" do
      delivery = Carriage::Delivery.create!(campaign: @campaign, subscriber: @subscriber)

      assert delivery.token.present?
    end

    test "register_open! sets opened_at only once" do
      delivery = Carriage::Delivery.create!(campaign: @campaign, subscriber: @subscriber)

      delivery.register_open!
      first_opened_at = delivery.opened_at

      travel 1.hour do
        delivery.register_open!
      end

      assert_equal first_opened_at, delivery.reload.opened_at
    end
  end
end

module Carriage
  class Subscriber < ApplicationRecord
    has_subscriptions

    has_many :subscriptions, class_name: "Carriage::Subscription", dependent: :destroy
    has_many :lists, through: :subscriptions, class_name: "Carriage::List"
    has_many :deliveries, class_name: "Carriage::Delivery", dependent: :destroy

    validates :email, presence: true, uniqueness: { case_sensitive: false }

    before_validation { self.email = email.strip.downcase if email }
  end
end

module Carriage
  class ConfirmationMailer < ApplicationMailer
    def confirm_email(subscription)
      @subscription = subscription
      @list = subscription.list
      @subscriber = subscription.subscriber
      @token = subscription.generate_token_for(:confirm_subscription)

      mail(to: @subscriber.email, subject: I18n.t("carriage.confirmation_mailer.confirm_email.subject", list: @list.name))
    end
  end
end

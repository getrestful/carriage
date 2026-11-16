module Carriage
  class ApplicationMailer < ActionMailer::Base
    default from: -> { Carriage.default_from_address }

    # Overrides the host's config.action_mailer.delivery_job for Carriage's
    # mailers only, so they retry even when the host configured nothing.
    self.delivery_job = Carriage::MailDeliveryJob
  end
end

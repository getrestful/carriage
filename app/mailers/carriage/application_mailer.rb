module Carriage
  class ApplicationMailer < ActionMailer::Base
    default from: -> { Carriage.default_from_address }

    self.delivery_job = Carriage::MailDeliveryJob
  end
end

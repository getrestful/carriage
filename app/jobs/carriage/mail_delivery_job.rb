module Carriage
  # Rails' stock MailDeliveryJob makes a single attempt; this one retries.
  class MailDeliveryJob < ActionMailer::MailDeliveryJob
    retry_on StandardError, wait: :polynomially_longer, attempts: Carriage.delivery_attempts
    discard_on ActiveJob::DeserializationError
  end
end

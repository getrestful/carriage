module Carriage
  # Delivery job for mail sent with deliver_later (the confirmation email).
  # Rails' stock MailDeliveryJob makes a single attempt, so a provider outage
  # would lose the mail; this retries on the same schedule as campaign sends.
  # StandardError rather than a list of SMTP errors because the host picks the
  # delivery method — Carriage can't know which errors it raises.
  class MailDeliveryJob < ActionMailer::MailDeliveryJob
    retry_on StandardError, wait: :polynomially_longer, attempts: Carriage.delivery_attempts
  end
end

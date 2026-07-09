module Carriage
  class CampaignMailer < ApplicationMailer
    def campaign_email(delivery)
      @delivery = delivery
      @campaign = delivery.campaign
      @subscriber = delivery.subscriber

      mjml_source = render_to_string(template: "carriage/campaign_mailer/campaign", formats: [ :mjml ], layout: false)
      html_body = Carriage::MjmlRenderer.render(mjml_source)
      html_body = Carriage::EmailTracking.instrument(html_body, @delivery)

      mail(to: @subscriber.email, subject: @campaign.subject) do |format|
        format.html { render html: html_body.html_safe, layout: false }
      end
    end
  end
end

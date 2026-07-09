module Carriage
  class CampaignMailer < ApplicationMailer
    def campaign_email(delivery)
      @delivery = delivery
      @campaign = delivery.campaign
      @subscriber = delivery.subscriber

      mjml_source = ActionText::Content.with_renderer(Carriage::ActionTextRenderer.renderer) do
        render_to_string(template: "carriage/campaign_mailer/campaign", formats: [ :mjml ], layout: false)
      end
      html_body = Carriage::MjmlRenderer.render(mjml_source)
      html_body = Carriage::EmailTracking.instrument(html_body, @delivery)

      mail(to: @subscriber.email, subject: @campaign.subject) do |format|
        format.html { render html: html_body.html_safe, layout: false }
      end
    end
  end
end

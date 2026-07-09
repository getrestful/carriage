module Carriage
  class CampaignsController < ApplicationController
    before_action :set_campaign, only: [ :show, :edit, :update, :destroy, :preview, :send_test, :send_now, :schedule, :duplicate ]

    def index
      @campaigns = Carriage::Campaign.order(created_at: :desc)
    end

    def show
      @stats = Carriage::CampaignStats.new(@campaign)
    end

    def new
      @campaign = Carriage::Campaign.new(list_id: params.dig(:campaign, :list_id))
    end

    def create
      @campaign = Carriage::Campaign.new(campaign_params)
      if @campaign.save
        redirect_to @campaign, notice: "Campaign created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @campaign.update(campaign_params)
        redirect_to @campaign, notice: "Campaign updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @campaign.destroy
      redirect_to campaigns_path, notice: "Campaign deleted."
    end

    def preview
      delivery = Carriage::Delivery.new(campaign: @campaign, subscriber: Carriage::Subscriber.new(email: "preview@example.com"), token: "preview")
      mjml_source = render_to_string(
        template: "carriage/campaign_mailer/campaign", formats: [ :mjml ], layout: false,
        assigns: { campaign: @campaign, delivery: delivery }
      )
      render html: Carriage::MjmlRenderer.render(mjml_source).html_safe
    end

    def send_test
      email = params[:test_email].to_s.strip
      if email.match?(URI::MailTo::EMAIL_REGEXP)
        Carriage::DeliverTestEmailJob.perform_later(@campaign.id, email)
        redirect_to @campaign, notice: "Test email queued for #{email}."
      else
        redirect_to @campaign, alert: "Enter a valid email address."
      end
    end

    def send_now
      Carriage::DeliverCampaignJob.perform_later(@campaign.id)
      redirect_to @campaign, notice: "Campaign is being sent."
    end

    def schedule
      scheduled_at = params[:scheduled_at].presence
      if scheduled_at
        @campaign.schedule!(scheduled_at)
        redirect_to @campaign, notice: "Campaign scheduled for #{@campaign.scheduled_at}."
      else
        redirect_to @campaign, alert: "Choose a date and time."
      end
    end

    def duplicate
      copy = @campaign.duplicate
      redirect_to edit_campaign_path(copy), notice: "Duplicated as a new draft."
    end

    private

    def set_campaign
      @campaign = Carriage::Campaign.find(params[:id])
    end

    def campaign_params
      params.require(:campaign).permit(:list_id, :name, :subject, :preheader, :heading, :body_html, :cta_label, :cta_url, :footer_text)
    end
  end
end

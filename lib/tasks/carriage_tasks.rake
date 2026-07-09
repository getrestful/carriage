namespace :carriage do
  desc "Enqueue delivery jobs for all campaigns whose scheduled_at has passed"
  task deliver_due_campaigns: :environment do
    Carriage::Campaign.where(status: "scheduled").where("scheduled_at <= ?", Time.current).find_each do |campaign|
      Carriage::DeliverCampaignJob.perform_later(campaign.id)
    end
  end
end

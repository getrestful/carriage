class RemoveBodyHtmlFromCarriageCampaigns < ActiveRecord::Migration[7.1]
  def change
    remove_column :carriage_campaigns, :body_html, :text
  end
end

class AddSegmentToCarriageCampaigns < ActiveRecord::Migration[8.1]
  def change
    add_reference :carriage_campaigns, :segment, null: true, foreign_key: { to_table: :carriage_segments }
  end
end

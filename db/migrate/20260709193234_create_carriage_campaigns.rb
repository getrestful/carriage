class CreateCarriageCampaigns < ActiveRecord::Migration[8.1]
  def change
    create_table :carriage_campaigns do |t|
      t.references :list, null: false, foreign_key: { to_table: :carriage_lists }
      t.string :name, null: false
      t.string :subject, null: false
      t.string :preheader
      t.string :heading
      t.text :body_html
      t.string :cta_label
      t.string :cta_url
      t.text :footer_text
      t.string :status, null: false, default: "draft"
      t.datetime :scheduled_at
      t.datetime :sent_at
      t.timestamps
    end
    add_index :carriage_campaigns, :status
    add_index :carriage_campaigns, :scheduled_at
  end
end

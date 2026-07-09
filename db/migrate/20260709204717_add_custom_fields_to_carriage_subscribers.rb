class AddCustomFieldsToCarriageSubscribers < ActiveRecord::Migration[8.1]
  def change
    add_column :carriage_subscribers, :custom_fields, :json, null: false, default: {}
  end
end

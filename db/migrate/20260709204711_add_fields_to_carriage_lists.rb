class AddFieldsToCarriageLists < ActiveRecord::Migration[8.1]
  def change
    add_column :carriage_lists, :fields, :json, null: false, default: []
  end
end

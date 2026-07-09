require "test_helper"

module Carriage
  class CsvExportTest < ActiveSupport::TestCase
    test "exports subscribers with their custom fields" do
      list = Carriage::List.create!(name: "Weekly", fields_text: "company")
      subscriber = Carriage::Subscriber.create!(email: "a@example.com", first_name: "Ada", custom_fields: { "company" => "Acme" })
      Carriage::Subscription.create!(list: list, subscriber: subscriber)

      csv = CSV.parse(Carriage::CsvExport.new(list).call, headers: true)

      assert_equal [ "email", "first_name", "last_name", "status", "company" ], csv.headers
      assert_equal "Acme", csv.first["company"]
      assert_equal "subscribed", csv.first["status"]
    end
  end
end

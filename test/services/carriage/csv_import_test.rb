require "test_helper"

module Carriage
  class CsvImportTest < ActiveSupport::TestCase
    test "imports valid rows, skips invalid rows, and dedupes existing list members" do
      list = Carriage::List.create!(name: "Weekly")
      existing = Carriage::Subscriber.create!(email: "alice@example.com")
      Carriage::Subscription.create!(list: list, subscriber: existing)

      path = file_fixture("sample_subscribers.csv").to_s
      mapping = { "email" => "email", "first_name" => "first_name", "last_name" => "last_name" }

      result = Carriage::CsvImport.new(list, path, mapping).call

      assert_equal 1, result.created
      assert_equal 1, result.skipped
      assert_equal 1, result.invalid
      assert list.subscribers.exists?(email: "bob@example.com")
    end

    test "imports custom field columns matched by name against the list's schema" do
      list = Carriage::List.create!(name: "Weekly", fields_text: "company")
      path = file_fixture("sample_subscribers_with_fields.csv").to_s
      mapping = { "email" => "email", "first_name" => "first_name", "last_name" => "last_name" }

      Carriage::CsvImport.new(list, path, mapping).call

      subscriber = Carriage::Subscriber.find_by(email: "alice@example.com")
      assert_equal "Acme", subscriber.custom_fields["company"]
    end
  end
end

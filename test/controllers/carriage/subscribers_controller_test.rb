require "test_helper"

module Carriage
  class SubscribersControllerTest < ActionDispatch::IntegrationTest
    test "create stores custom field values declared on the list's schema" do
      list = Carriage::List.create!(name: "Weekly", fields_text: "company")

      post "/carriage/lists/#{list.id}/subscribers", params: {
        subscriber: { email: "a@example.com", custom_fields: { "company" => "Acme", "ignored" => "x" } }
      }

      subscriber = Carriage::Subscriber.find_by(email: "a@example.com")
      assert_equal({ "company" => "Acme" }, subscriber.custom_fields)
    end
  end
end

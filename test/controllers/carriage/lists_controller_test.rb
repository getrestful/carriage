require "test_helper"

module Carriage
  class ListsControllerTest < ActionDispatch::IntegrationTest
    test "creates a list" do
      assert_difference "Carriage::List.count", 1 do
        post "/carriage/lists", params: { list: { name: "Weekly" } }
      end

      list = Carriage::List.last
      assert_redirected_to "/carriage/lists/#{list.id}"
    end

    test "shows a list with its subscribers" do
      list = Carriage::List.create!(name: "Weekly")
      subscriber = Carriage::Subscriber.create!(email: "a@example.com")
      Carriage::Subscription.create!(list: list, subscriber: subscriber)

      get "/carriage/lists/#{list.id}"

      assert_response :success
      assert_match "a@example.com", response.body
    end

    test "export downloads a CSV of the list's subscribers" do
      list = Carriage::List.create!(name: "Weekly")
      subscriber = Carriage::Subscriber.create!(email: "a@example.com", first_name: "Ada")
      Carriage::Subscription.create!(list: list, subscriber: subscriber)

      get "/carriage/lists/#{list.id}/export"

      assert_response :success
      assert_equal "text/csv", response.media_type
      assert_match "a@example.com", response.body
      assert_match "Ada", response.body
    end

    test "update saves the custom field schema from fields_text" do
      list = Carriage::List.create!(name: "Weekly")

      patch "/carriage/lists/#{list.id}", params: { list: { fields_text: "company\nrole" } }

      assert_equal [ "company", "role" ], list.reload.field_names
    end
  end
end

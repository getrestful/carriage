require "test_helper"

module Carriage
  class SegmentsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @list = Carriage::List.create!(name: "Weekly", fields_text: "plan")
    end

    test "creates a segment from conditions_text" do
      assert_difference "Carriage::Segment.count", 1 do
        post "/carriage/segments", params: { segment: { list_id: @list.id, name: "Pro plan", conditions_text: "plan equals pro" } }
      end

      segment = Carriage::Segment.last
      assert_redirected_to "/carriage/segments/#{segment.id}"
      assert_equal [ { "field" => "plan", "operator" => "equals", "value" => "pro" } ], segment.conditions
    end

    test "does not create a segment with an invalid condition" do
      assert_no_difference "Carriage::Segment.count" do
        post "/carriage/segments", params: { segment: { list_id: @list.id, name: "Bad", conditions_text: "nope equals pro" } }
      end

      assert_response :unprocessable_entity
    end

    test "shows a segment with its matching subscribers" do
      subscriber = Carriage::Subscriber.create!(email: "a@example.com", custom_fields: { "plan" => "pro" })
      Carriage::Subscription.create!(list: @list, subscriber: subscriber)
      segment = Carriage::Segment.create!(list: @list, name: "Pro plan", conditions_text: "plan equals pro")

      get "/carriage/segments/#{segment.id}"

      assert_response :success
      assert_match "a@example.com", response.body
    end

    test "updates a segment's conditions" do
      segment = Carriage::Segment.create!(list: @list, name: "Pro plan", conditions_text: "plan equals pro")

      patch "/carriage/segments/#{segment.id}", params: { segment: { conditions_text: "plan equals vip" } }

      assert_equal [ { "field" => "plan", "operator" => "equals", "value" => "vip" } ], segment.reload.conditions
    end

    test "deletes a segment" do
      segment = Carriage::Segment.create!(list: @list, name: "Pro plan")

      assert_difference "Carriage::Segment.count", -1 do
        delete "/carriage/segments/#{segment.id}"
      end
    end
  end
end

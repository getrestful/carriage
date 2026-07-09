# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_07_09_210001) do
  create_table "carriage_campaigns", force: :cascade do |t|
    t.text "body_html"
    t.datetime "created_at", null: false
    t.string "cta_label"
    t.string "cta_url"
    t.text "footer_text"
    t.string "heading"
    t.integer "list_id", null: false
    t.string "name", null: false
    t.string "preheader"
    t.datetime "scheduled_at"
    t.integer "segment_id"
    t.datetime "sent_at"
    t.string "status", default: "draft", null: false
    t.string "subject", null: false
    t.datetime "updated_at", null: false
    t.index ["list_id"], name: "index_carriage_campaigns_on_list_id"
    t.index ["scheduled_at"], name: "index_carriage_campaigns_on_scheduled_at"
    t.index ["segment_id"], name: "index_carriage_campaigns_on_segment_id"
    t.index ["status"], name: "index_carriage_campaigns_on_status"
  end

  create_table "carriage_clicks", force: :cascade do |t|
    t.integer "click_count", default: 0, null: false
    t.datetime "clicked_at"
    t.datetime "created_at", null: false
    t.integer "delivery_id", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.text "url", null: false
    t.index ["delivery_id"], name: "index_carriage_clicks_on_delivery_id"
    t.index ["token"], name: "index_carriage_clicks_on_token", unique: true
  end

  create_table "carriage_deliveries", force: :cascade do |t|
    t.integer "campaign_id", null: false
    t.datetime "created_at", null: false
    t.text "error_message"
    t.boolean "is_test", default: false, null: false
    t.datetime "opened_at"
    t.datetime "sent_at"
    t.string "state", default: "pending", null: false
    t.integer "subscriber_id", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["campaign_id", "subscriber_id"], name: "index_carriage_deliveries_on_campaign_and_subscriber", unique: true
    t.index ["campaign_id"], name: "index_carriage_deliveries_on_campaign_id"
    t.index ["subscriber_id"], name: "index_carriage_deliveries_on_subscriber_id"
    t.index ["token"], name: "index_carriage_deliveries_on_token", unique: true
  end

  create_table "carriage_lists", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.json "fields", default: [], null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_carriage_lists_on_name", unique: true
  end

  create_table "carriage_segments", force: :cascade do |t|
    t.json "conditions", default: [], null: false
    t.datetime "created_at", null: false
    t.integer "list_id", null: false
    t.string "match_type", default: "all", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["list_id", "name"], name: "index_carriage_segments_on_list_and_name", unique: true
    t.index ["list_id"], name: "index_carriage_segments_on_list_id"
  end

  create_table "carriage_subscribers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "custom_fields", default: {}, null: false
    t.string "email", null: false
    t.string "first_name"
    t.string "last_name"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_carriage_subscribers_on_email", unique: true
  end

  create_table "carriage_subscriptions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "list_id", null: false
    t.integer "subscriber_id", null: false
    t.datetime "unsubscribed_at"
    t.datetime "updated_at", null: false
    t.index ["list_id", "subscriber_id"], name: "index_carriage_subscriptions_on_list_and_subscriber", unique: true
    t.index ["list_id"], name: "index_carriage_subscriptions_on_list_id"
    t.index ["subscriber_id"], name: "index_carriage_subscriptions_on_subscriber_id"
  end

  create_table "mailkick_subscriptions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "list"
    t.integer "subscriber_id"
    t.string "subscriber_type"
    t.datetime "updated_at", null: false
    t.index ["subscriber_type", "subscriber_id", "list"], name: "index_mailkick_subscriptions_on_subscriber_and_list", unique: true
  end

  add_foreign_key "carriage_campaigns", "carriage_lists", column: "list_id"
  add_foreign_key "carriage_campaigns", "carriage_segments", column: "segment_id"
  add_foreign_key "carriage_clicks", "carriage_deliveries", column: "delivery_id"
  add_foreign_key "carriage_deliveries", "carriage_campaigns", column: "campaign_id"
  add_foreign_key "carriage_deliveries", "carriage_subscribers", column: "subscriber_id"
  add_foreign_key "carriage_segments", "carriage_lists", column: "list_id"
  add_foreign_key "carriage_subscriptions", "carriage_lists", column: "list_id"
  add_foreign_key "carriage_subscriptions", "carriage_subscribers", column: "subscriber_id"
end

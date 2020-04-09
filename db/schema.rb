# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_02_05_183726) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "unaccent"

  create_table "ad_archive_report_pages", force: :cascade do |t|
    t.bigint "page_id"
    t.string "page_name"
    t.string "disclaimer"
    t.integer "amount_spent"
    t.integer "ads_count"
    t.integer "ad_archive_report_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "ads_this_tranche"
    t.integer "spend_this_tranche"
    t.integer "amount_spent_since_start_date"
    t.index ["ad_archive_report_id", "page_id"], name: "index_ad_archive_report_pages_on_ad_archive_report_id_page_id"
  end

  create_table "ad_archive_reports", force: :cascade do |t|
    t.datetime "scrape_date"
    t.text "s3_url"
    t.text "kind"
    t.boolean "loaded", default: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "ad_texts", force: :cascade do |t|
    t.text "text"
    t.string "text_hash"
    t.text "vec"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "search_text"
    t.index "to_tsvector('english'::regconfig, search_text)", name: "index_ads_on_search_text", using: :gin
  end

  create_table "ad_topics", force: :cascade do |t|
    t.bigint "archive_id"
    t.integer "topic_id"
    t.float "proportion"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "ad_text_id"
  end

  create_table "ads", id: false, force: :cascade do |t|
    t.text "ad_creative_body"
    t.datetime "ad_delivery_start_time", precision: 4
    t.datetime "ad_delivery_stop_time", precision: 4
    t.datetime "ad_creation_time", precision: 4
    t.bigint "page_id"
    t.string "currency", limit: 255
    t.string "ad_snapshot_url"
    t.boolean "is_active"
    t.integer "ad_sponsor_id"
    t.bigint "archive_id", null: false
    t.bigserial "nyu_id", null: false
    t.string "ad_creative_link_caption"
    t.string "ad_creative_link_description"
    t.string "ad_creative_link_title"
    t.integer "ad_category_id"
    t.bigint "ad_id"
    t.string "country_code"
    t.boolean "most_recent"
    t.string "funding_entity"
    t.index ["archive_id"], name: "unique_ad_archive_id", unique: true
  end

  create_table "big_spenders", force: :cascade do |t|
    t.integer "ad_archive_report_id"
    t.integer "previous_ad_archive_report_id"
    t.integer "ad_archive_report_page_id"
    t.bigint "page_id"
    t.integer "spend_amount"
    t.integer "duration_days"
    t.boolean "is_new"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "demo_groups", id: :serial, force: :cascade do |t|
    t.string "age", limit: 255
    t.string "gender", limit: 255
  end

  create_table "demo_impressions", id: false, force: :cascade do |t|
    t.bigint "ad_archive_id"
    t.integer "demo_id"
    t.integer "min_impressions"
    t.integer "max_impressions"
    t.integer "min_spend"
    t.integer "max_spend"
    t.date "crawl_date"
    t.boolean "most_recent"
    t.bigint "nyu_id", default: -> { "nextval('demo_impressions_nyu_id1_seq'::regclass)" }, null: false
    t.index ["ad_archive_id", "demo_id"], name: "demo_impressions_unique_ad_archive_id", unique: true
    t.index ["ad_archive_id"], name: "demo_impressions_archive_id_idx"
  end

  create_table "fbpac_ads", id: :text, force: :cascade do |t|
    t.text "html", null: false
    t.integer "political", null: false
    t.integer "not_political", null: false
    t.text "title", null: false
    t.text "message", null: false
    t.text "thumbnail", null: false
    t.datetime "created_at", default: -> { "now()" }, null: false
    t.datetime "updated_at", default: -> { "now()" }, null: false
    t.text "lang", null: false
    t.text "images", null: false, array: true
    t.integer "impressions", default: 1, null: false
    t.float "political_probability", default: 0.0, null: false
    t.text "targeting"
    t.boolean "suppressed", default: false, null: false
    t.jsonb "targets", default: []
    t.text "advertiser"
    t.jsonb "entities", default: []
    t.text "page"
    t.string "lower_page"
    t.text "targetings", array: true
    t.text "paid_for_by"
    t.integer "targetedness"
    t.decimal "listbuilding_fundraising_proba", precision: 9, scale: 6
    t.index ["advertiser"], name: "index_fbpac_ads_on_advertiser"
    t.index ["entities"], name: "index_fbpac_ads_on_entities", using: :gin
    t.index ["lang"], name: "index_fbpac_ads_on_browser_lang"
    t.index ["lower_page"], name: "fbpac_ads_lower_page_idx"
    t.index ["page"], name: "index_fbpac_ads_on_page"
    t.index ["political_probability"], name: "index_fbpac_ads_on_political_probability"
    t.index ["targets"], name: "index_fbpac_ads_on_targets", using: :gin
  end

  create_table "impressions", id: false, force: :cascade do |t|
    t.bigint "ad_archive_id"
    t.date "crawl_date"
    t.integer "min_impressions"
    t.integer "min_spend"
    t.integer "max_impressions"
    t.integer "max_spend"
    t.boolean "most_recent"
    t.bigint "nyu_id", default: -> { "nextval('impressions_nyu_id1_seq'::regclass)" }, null: false
    t.index ["ad_archive_id"], name: "impressions_archive_id_idx"
    t.index ["ad_archive_id"], name: "impressions_unique_ad_archive_id", unique: true
  end

  create_table "pages", id: false, force: :cascade do |t|
    t.string "page_name", limit: 255
    t.bigint "page_id"
    t.boolean "federal_candidate"
    t.string "url"
    t.boolean "is_deleted"
  end

  create_table "payers", force: :cascade do |t|
    t.string "name"
    t.text "notes"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "region_impressions", id: false, force: :cascade do |t|
    t.bigint "ad_archive_id"
    t.integer "region_id"
    t.integer "min_impressions"
    t.integer "min_spend"
    t.integer "max_impressions"
    t.integer "max_spend"
    t.date "crawl_date"
    t.boolean "most_recent"
    t.bigint "nyu_id", default: -> { "nextval('region_impressions_nyu_id1_seq'::regclass)" }, null: false
    t.index ["ad_archive_id", "region_id"], name: "region_impressions_unique_ad_archive_id", unique: true
    t.index ["ad_archive_id"], name: "region_impressions_archive_id_idx"
  end

  create_table "regions", id: :serial, force: :cascade do |t|
    t.string "name"
  end

  create_table "topics", force: :cascade do |t|
    t.string "topic"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "writable_ads", force: :cascade do |t|
    t.string "partisanship"
    t.string "purpose"
    t.string "optimism"
    t.string "attack"
    t.bigint "archive_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "text_hash"
    t.text "ad_id"
    t.index ["text_hash"], name: "index_writable_ads_on_text_hash"
  end

  create_table "writable_pages", force: :cascade do |t|
    t.bigint "page_id"
    t.text "notes"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "disclaimer"
  end

end

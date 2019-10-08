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

ActiveRecord::Schema.define(version: 2019_10_08_172936) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "ad_topics", force: :cascade do |t|
    t.bigint "archive_id"
    t.integer "topic_id"
    t.float "proportion"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "ads", id: false, force: :cascade do |t|
    t.text "text"
    t.datetime "start_date", precision: 4
    t.datetime "end_date", precision: 4
    t.datetime "creation_date", precision: 4
    t.bigint "page_id"
    t.string "currency", limit: 255
    t.string "snapshot_url"
    t.boolean "is_active"
    t.integer "ad_sponsor_id"
    t.bigint "archive_id", null: false
    t.bigserial "nyu_id", null: false
    t.string "link_caption"
    t.string "link_description"
    t.string "link_title"
    t.integer "ad_category_id"
    t.bigint "ad_id"
    t.string "country_code"
    t.boolean "most_recent"
    t.string "funding_entity"
    t.index ["archive_id"], name: "unique_ad_archive_id", unique: true
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

  create_table "writable_ads", force: :cascade do |t|
    t.string "partisanship"
    t.string "purpose"
    t.string "optimism"
    t.string "attack"
    t.bigint "archive_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "writable_pages", force: :cascade do |t|
    t.bigint "page_id"
    t.text "notes"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

end

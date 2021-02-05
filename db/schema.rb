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

ActiveRecord::Schema.define(version: 2021_02_05_092330) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "auctions", force: :cascade do |t|
    t.bigint "item_id"
    t.bigint "auction_id"
    t.integer "true_item_id"
    t.string "owner"
    t.string "region"
    t.string "owner_realm"
    t.integer "quantity"
    t.bigint "buyout"
    t.bigint "bid"
    t.string "time_left"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["auction_id"], name: "index_auctions_on_auction_id"
    t.index ["item_id"], name: "index_auctions_on_item_id"
  end

  create_table "item_medias", force: :cascade do |t|
    t.bigint "item_id"
    t.string "url"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["item_id"], name: "index_item_medias_on_item_id"
  end

  create_table "item_names", force: :cascade do |t|
    t.bigint "item_id"
    t.string "locale"
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["item_id"], name: "index_item_names_on_item_id"
  end

  create_table "items", force: :cascade do |t|
    t.integer "item_id"
    t.string "quality"
    t.integer "level"
    t.bigint "required_level"
    t.integer "item_class"
    t.integer "item_subclass"
    t.integer "inventory_type"
    t.integer "purchase_price"
    t.integer "sell_price"
    t.integer "max_count"
    t.boolean "is_equippable"
    t.boolean "is_stackable"
    t.string "binding"
    t.string "unique"
    t.string "info_table"
    t.integer "info_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["item_id"], name: "index_items_on_item_id"
  end

  create_table "realms", force: :cascade do |t|
    t.bigint "item_id"
    t.string "region"
    t.string "name"
    t.string "slug"
    t.string "battlegroup"
    t.string "locale"
    t.string "population"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["item_id"], name: "index_realms_on_item_id"
  end

  create_table "stats", force: :cascade do |t|
    t.bigint "item_id"
    t.string "stat_type"
    t.integer "value"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["item_id"], name: "index_stats_on_item_id"
  end

  create_table "weapons", force: :cascade do |t|
    t.bigint "item_id"
    t.integer "dmg_min"
    t.integer "dmg_max"
    t.string "damage_class"
    t.integer "attack_speed"
    t.float "dps"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["item_id"], name: "index_weapons_on_item_id"
  end

end

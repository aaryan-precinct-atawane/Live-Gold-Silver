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

ActiveRecord::Schema[8.1].define(version: 2026_11_24_130001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "practice_accounts", force: :cascade do |t|
    t.string "token", null: false
    t.decimal "balance_inr", precision: 14, scale: 2, default: "1000000.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token"], name: "index_practice_accounts_on_token", unique: true
  end

  create_table "practice_trades", force: :cascade do |t|
    t.bigint "practice_account_id", null: false
    t.string "metal", null: false
    t.string "direction", null: false
    t.decimal "stake_inr", precision: 14, scale: 2, null: false
    t.integer "leverage", null: false
    t.integer "duration_seconds", null: false
    t.decimal "entry_price_usd", precision: 14, scale: 4, null: false
    t.decimal "exit_price_usd", precision: 14, scale: 4
    t.string "status", default: "open", null: false
    t.string "close_reason"
    t.decimal "pnl_inr", precision: 14, scale: 2
    t.datetime "opened_at", null: false
    t.datetime "expires_at", null: false
    t.datetime "closed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["practice_account_id", "status"], name: "index_practice_trades_on_practice_account_id_and_status"
    t.index ["status", "expires_at"], name: "index_practice_trades_on_status_and_expires_at"
  end

  create_table "price_quotes", force: :cascade do |t|
    t.string "metal", null: false
    t.decimal "price_inr", precision: 12, scale: 2, null: false
    t.decimal "price_usd", precision: 12, scale: 2, null: false
    t.datetime "recorded_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "usd_inr_rate", precision: 10, scale: 4, null: false
    t.string "source", null: false
    t.index ["metal", "recorded_at"], name: "index_price_quotes_on_metal_and_recorded_at"
  end

  add_foreign_key "practice_trades", "practice_accounts", on_delete: :cascade
end

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

ActiveRecord::Schema[8.1].define(version: 2026_10_03_161922) do
  create_table "groups", force: :cascade do |t|
    t.string "name", null: false
    t.string "invite_code", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invite_code"], name: "index_groups_on_invite_code", unique: true
  end

  create_table "memberships", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "group_id", null: false
    t.string "role", default: "member", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id", "user_id"], name: "index_memberships_on_group_id_and_user_id", unique: true
    t.index ["group_id"], name: "index_memberships_on_group_id"
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "prizes", force: :cascade do |t|
    t.integer "group_id", null: false
    t.date "month", null: false
    t.string "description", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id", "month"], name: "index_prizes_on_group_id_and_month", unique: true
    t.index ["group_id"], name: "index_prizes_on_group_id"
  end

  create_table "results", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "game", null: false
    t.date "played_on", null: false
    t.integer "puzzle_number"
    t.boolean "solved", default: false, null: false
    t.integer "score_value"
    t.string "breakdown"
    t.decimal "points", precision: 4, scale: 1, default: "0.0", null: false
    t.text "share_text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["played_on"], name: "index_results_on_played_on"
    t.index ["user_id", "game", "played_on"], name: "index_results_on_user_id_and_game_and_played_on", unique: true
    t.index ["user_id"], name: "index_results_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "memberships", "groups"
  add_foreign_key "memberships", "users"
  add_foreign_key "prizes", "groups"
  add_foreign_key "results", "users"
  add_foreign_key "sessions", "users"
end

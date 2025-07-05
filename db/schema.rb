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

ActiveRecord::Schema[8.1].define(version: 2025_07_05_032040) do
  create_table "areas", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "game_id", null: false
    t.string "name"
    t.json "properties"
    t.datetime "updated_at", null: false
    t.index [ "game_id" ], name: "index_areas_on_game_id"
  end

  create_table "characters", force: :cascade do |t|
    t.integer "area_id"
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "game_id", null: false
    t.boolean "is_player", default: false, null: false
    t.string "name"
    t.json "properties"
    t.datetime "updated_at", null: false
    t.index [ "area_id" ], name: "index_characters_on_area_id"
    t.index [ "game_id", "is_player" ], name: "index_characters_on_game_id_and_is_player", unique: true, where: "is_player = true"
    t.index [ "game_id" ], name: "index_characters_on_game_id"
  end

  create_table "game_configuration_messages", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.integer "game_configuration_session_id", null: false
    t.string "model"
    t.string "role"
    t.json "tool_calls"
    t.json "tool_results"
    t.datetime "updated_at", null: false
    t.index [ "game_configuration_session_id" ], name: "idx_on_game_configuration_session_id_1f395c0ebb"
  end

  create_table "game_configuration_sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "game_id", null: false
    t.datetime "updated_at", null: false
    t.index [ "game_id" ], name: "index_game_configuration_sessions_on_game_id"
  end

  create_table "games", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "llm_adapter"
    t.string "name"
    t.integer "state", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index [ "user_id" ], name: "index_games_on_user_id"
  end

  create_table "message_witnesses", force: :cascade do |t|
    t.integer "character_id", null: false
    t.datetime "created_at", null: false
    t.integer "message_id", null: false
    t.datetime "updated_at", null: false
    t.index [ "character_id" ], name: "index_message_witnesses_on_character_id"
    t.index [ "message_id", "character_id" ], name: "index_message_witnesses_on_message_id_and_character_id", unique: true
    t.index [ "message_id" ], name: "index_message_witnesses_on_message_id"
  end

  create_table "messages", force: :cascade do |t|
    t.integer "area_id"
    t.integer "character_id"
    t.text "content"
    t.datetime "created_at", null: false
    t.integer "game_id", null: false
    t.boolean "is_dm_whisper", default: false, null: false
    t.string "message_type"
    t.datetime "updated_at", null: false
    t.index [ "area_id" ], name: "index_messages_on_area_id"
    t.index [ "character_id" ], name: "index_messages_on_character_id"
    t.index [ "game_id" ], name: "index_messages_on_game_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index [ "user_id" ], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index [ "email_address" ], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "areas", "games"
  add_foreign_key "characters", "areas"
  add_foreign_key "characters", "games"
  add_foreign_key "game_configuration_messages", "game_configuration_sessions"
  add_foreign_key "game_configuration_sessions", "games"
  add_foreign_key "games", "users"
  add_foreign_key "message_witnesses", "characters"
  add_foreign_key "message_witnesses", "messages"
  add_foreign_key "messages", "areas"
  add_foreign_key "messages", "characters"
  add_foreign_key "messages", "games"
  add_foreign_key "sessions", "users"
end

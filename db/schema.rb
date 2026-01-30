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

ActiveRecord::Schema[8.0].define(version: 2026_01_30_200523) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_stat_statements"

  create_table "achievements", force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.string "icon"
    t.string "achievement_type"
    t.integer "reward_points", default: 0
    t.string "owner_uuid"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "name"], name: "index_achievements_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_achievements_on_user_id"
  end

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "bingo_cards", force: :cascade do |t|
    t.bigint "bingo_game_id", null: false
    t.bigint "user_id", null: false
    t.integer "replacement_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bingo_game_id"], name: "index_bingo_cards_on_bingo_game_id"
    t.index ["user_id"], name: "index_bingo_cards_on_user_id"
  end

  create_table "bingo_cells", force: :cascade do |t|
    t.bigint "bingo_card_id", null: false
    t.bigint "bingo_item_id", null: false
    t.string "coordinate"
    t.boolean "is_marked", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bingo_card_id"], name: "index_bingo_cells_on_bingo_card_id"
    t.index ["bingo_item_id"], name: "index_bingo_cells_on_bingo_item_id"
  end

  create_table "bingo_game_items", force: :cascade do |t|
    t.bigint "bingo_game_id", null: false
    t.bigint "bingo_item_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bingo_game_id"], name: "index_bingo_game_items_on_bingo_game_id"
    t.index ["bingo_item_id"], name: "index_bingo_game_items_on_bingo_item_id"
  end

  create_table "bingo_game_mark_memories", force: :cascade do |t|
    t.bigint "bingo_game_id", null: false
    t.string "coordinate", null: false
    t.bigint "approved_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["approved_by_id"], name: "index_bingo_game_mark_memories_on_approved_by_id"
    t.index ["bingo_game_id", "coordinate"], name: "index_bingo_game_mark_memories_on_bingo_game_id_and_coordinate", unique: true
    t.index ["bingo_game_id"], name: "index_bingo_game_mark_memories_on_bingo_game_id"
  end

  create_table "bingo_games", force: :cascade do |t|
    t.bigint "host_id", null: false
    t.bigint "winner_id"
    t.string "title"
    t.string "status", default: "invite"
    t.integer "size", default: 5
    t.datetime "started_at"
    t.datetime "ended_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["host_id"], name: "index_bingo_games_on_host_id"
    t.index ["winner_id"], name: "index_bingo_games_on_winner_id"
  end

  create_table "bingo_items", force: :cascade do |t|
    t.integer "row_number"
    t.string "column_letter"
    t.string "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "blocks", force: :cascade do |t|
    t.bigint "section_id", null: false
    t.integer "block_type", null: false
    t.text "content"
    t.string "block_link"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["section_id"], name: "index_blocks_on_section_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "comments", force: :cascade do |t|
    t.text "content"
    t.bigint "user_id"
    t.string "commentable_type"
    t.bigint "commentable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["commentable_type", "commentable_id"], name: "index_comments_on_commentable_type_and_commentable_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "contact_messages", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.string "phone"
    t.text "properties"
    t.string "subject"
    t.text "body"
    t.datetime "read_at"
    t.string "ip_address"
    t.string "country_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "custom_commands", force: :cascade do |t|
    t.string "name", null: false
    t.text "response", null: false
    t.string "author", null: false
    t.string "permission_level", default: "everyone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_custom_commands_on_name", unique: true
  end

  create_table "downloads", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.string "link_url"
    t.string "link_text"
    t.integer "order", default: 0
    t.bigint "category_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_downloads_on_category_id"
  end

  create_table "events", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.string "location"
    t.string "slug"
    t.string "timezone"
    t.datetime "start_time"
    t.datetime "end_time"
    t.bigint "user_id"
    t.bigint "category_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_events_on_category_id"
    t.index ["user_id"], name: "index_events_on_user_id"
  end

  create_table "giveaway_entries", force: :cascade do |t|
    t.bigint "giveaway_id", null: false
    t.bigint "user_id", null: false
    t.integer "tickets_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["giveaway_id", "user_id"], name: "index_giveaway_entries_on_giveaway_id_and_user_id", unique: true
    t.index ["giveaway_id"], name: "index_giveaway_entries_on_giveaway_id"
    t.index ["user_id"], name: "index_giveaway_entries_on_user_id"
  end

  create_table "giveaways", force: :cascade do |t|
    t.string "title"
    t.integer "giveaway_type", default: 0
    t.integer "status", default: 0
    t.integer "max_entries_per_user"
    t.integer "min_karma", default: 0
    t.integer "min_fame", default: 0
    t.bigint "winner_id"
    t.datetime "drawn_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ticket_cost", default: 1, null: false
    t.index ["winner_id"], name: "index_giveaways_on_winner_id"
  end

  create_table "investments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "amount", null: false
    t.decimal "interest_rate", precision: 5, scale: 4, default: "0.01"
    t.integer "status", default: 0
    t.string "investment_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "purchase_price"
    t.index ["user_id"], name: "index_investments_on_user_id"
  end

  create_table "ledger_entries", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "amount", null: false
    t.string "entry_type", null: false
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["entry_type"], name: "index_ledger_entries_on_entry_type"
    t.index ["user_id"], name: "index_ledger_entries_on_user_id"
  end

  create_table "media", force: :cascade do |t|
    t.string "file"
    t.text "meta_description"
    t.text "meta_keywords"
    t.boolean "approved"
    t.boolean "screenshot_of_week"
    t.string "category"
    t.boolean "staff", default: false
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_media_on_user_id"
  end

  create_table "menu_items", force: :cascade do |t|
    t.string "title"
    t.string "url"
    t.integer "position"
    t.integer "parent_id"
    t.integer "item_type", default: 0, null: false
    t.integer "item_id"
    t.bigint "menu_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["menu_id"], name: "index_menu_items_on_menu_id"
  end

  create_table "menus", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "pages", force: :cascade do |t|
    t.string "title", null: false
    t.text "content"
    t.string "slug"
    t.boolean "published"
    t.string "template"
    t.bigint "user_id"
    t.bigint "category_id"
    t.text "meta_description"
    t.text "meta_keywords"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_pages_on_category_id"
    t.index ["user_id"], name: "index_pages_on_user_id"
  end

  create_table "pending_actions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "target_type", null: false
    t.bigint "target_id", null: false
    t.string "action_type"
    t.string "status", default: "pending"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["target_type", "target_id"], name: "index_pending_actions_on_target"
    t.index ["user_id"], name: "index_pending_actions_on_user_id"
  end

  create_table "posts", force: :cascade do |t|
    t.string "title"
    t.text "content"
    t.boolean "published"
    t.integer "views"
    t.boolean "trashed"
    t.bigint "user_id"
    t.bigint "category_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_posts_on_category_id"
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "price_histories", force: :cascade do |t|
    t.bigint "ticker_id", null: false
    t.decimal "price"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "volume", default: 0.0
    t.float "open"
    t.float "high"
    t.float "low"
    t.float "close"
    t.index ["ticker_id"], name: "index_price_histories_on_ticker_id"
  end

  create_table "raffle_entries", force: :cascade do |t|
    t.bigint "raffle_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["raffle_id", "user_id"], name: "index_raffle_entries_on_raffle_id_and_user_id", unique: true
    t.index ["raffle_id"], name: "index_raffle_entries_on_raffle_id"
    t.index ["user_id"], name: "index_raffle_entries_on_user_id"
  end

  create_table "raffles", force: :cascade do |t|
    t.bigint "host_id", null: false
    t.string "status", default: "active"
    t.integer "max_participants", default: 500
    t.integer "prize_amount", default: 0
    t.integer "winner_id"
    t.datetime "ended_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "raffle_type"
    t.index ["host_id"], name: "index_raffles_on_host_id"
  end

  create_table "sections", force: :cascade do |t|
    t.string "name", null: false
    t.string "template", null: false
    t.integer "animation_speed"
    t.integer "position"
    t.string "subtitle"
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "services", force: :cascade do |t|
    t.string "title", null: false
    t.text "content"
    t.string "slug"
    t.boolean "published"
    t.bigint "category_id"
    t.text "meta_description"
    t.text "meta_keywords"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_services_on_category_id"
  end

  create_table "settings", force: :cascade do |t|
    t.string "key"
    t.text "value"
    t.string "group"
    t.string "setting_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "system_settings", force: :cascade do |t|
    t.string "broadcaster_uid"
    t.string "bot_uid"
    t.boolean "bot_enabled", default: false, null: false
    t.integer "singleton_guard", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["singleton_guard"], name: "index_system_settings_on_singleton_guard", unique: true
  end

  create_table "taggings", force: :cascade do |t|
    t.bigint "tag_id", null: false
    t.string "taggable_type", null: false
    t.bigint "taggable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tag_id", "taggable_type", "taggable_id"], name: "index_taggings_on_tag_id_and_taggable_type_and_taggable_id", unique: true
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_type", "taggable_id"], name: "index_taggings_on_taggable_type_and_taggable_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "testimonials", force: :cascade do |t|
    t.string "title", null: false
    t.text "content"
    t.bigint "category_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_testimonials_on_category_id"
  end

  create_table "tickers", force: :cascade do |t|
    t.string "name"
    t.decimal "current_price"
    t.decimal "previous_price"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "buy_pressure", default: 0.0
    t.float "sell_pressure", default: 0.0
    t.text "description"
    t.string "symbol"
    t.float "liquidity", default: 1000.0
    t.float "max_liquidity", default: 1000.0
  end

  create_table "users", force: :cascade do |t|
    t.string "uid", null: false
    t.string "provider"
    t.string "username"
    t.integer "user_type"
    t.integer "karma", default: 0
    t.integer "fame", default: 0
    t.string "first_name"
    t.string "last_name"
    t.string "avatar"
    t.string "ip_address"
    t.string "country"
    t.string "twitch_access_token"
    t.string "twitch_refresh_token"
    t.datetime "last_login"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "wallet", default: 0, null: false
    t.index ["uid"], name: "index_users_on_uid", unique: true
  end

  add_foreign_key "achievements", "users"
  add_foreign_key "bingo_cards", "bingo_games"
  add_foreign_key "bingo_cards", "users"
  add_foreign_key "bingo_cells", "bingo_cards"
  add_foreign_key "bingo_cells", "bingo_items"
  add_foreign_key "bingo_game_items", "bingo_games"
  add_foreign_key "bingo_game_items", "bingo_items"
  add_foreign_key "bingo_game_mark_memories", "bingo_games"
  add_foreign_key "bingo_game_mark_memories", "users", column: "approved_by_id"
  add_foreign_key "bingo_games", "users", column: "host_id"
  add_foreign_key "bingo_games", "users", column: "winner_id"
  add_foreign_key "blocks", "sections"
  add_foreign_key "comments", "users"
  add_foreign_key "downloads", "categories"
  add_foreign_key "events", "categories"
  add_foreign_key "events", "users"
  add_foreign_key "giveaway_entries", "giveaways"
  add_foreign_key "giveaway_entries", "users"
  add_foreign_key "giveaways", "users", column: "winner_id"
  add_foreign_key "investments", "users"
  add_foreign_key "ledger_entries", "users"
  add_foreign_key "media", "users"
  add_foreign_key "menu_items", "menus"
  add_foreign_key "pages", "categories"
  add_foreign_key "pages", "users"
  add_foreign_key "pending_actions", "users"
  add_foreign_key "posts", "categories"
  add_foreign_key "posts", "users"
  add_foreign_key "price_histories", "tickers"
  add_foreign_key "raffle_entries", "raffles"
  add_foreign_key "raffle_entries", "users"
  add_foreign_key "raffles", "users", column: "host_id"
  add_foreign_key "services", "categories"
  add_foreign_key "taggings", "tags"
  add_foreign_key "testimonials", "categories"
end

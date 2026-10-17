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

ActiveRecord::Schema[8.1].define(version: 2026_10_17_220100) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "link_requests", force: :cascade do |t|
    t.bigint "radio_id", null: false
    t.bigint "user_id", null: false
    t.string "other_node", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["radio_id"], name: "index_link_requests_on_radio_id"
    t.index ["user_id"], name: "index_link_requests_on_user_id"
  end

  create_table "radio_events", force: :cascade do |t|
    t.bigint "radio_id"
    t.bigint "server_id"
    t.bigint "user_id"
    t.string "kind", null: false
    t.string "unit_identifier"
    t.string "decoder"
    t.string "other_node"
    t.datetime "occurred_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["occurred_at"], name: "index_radio_events_on_occurred_at"
    t.index ["radio_id"], name: "index_radio_events_on_radio_id"
    t.index ["server_id"], name: "index_radio_events_on_server_id"
    t.index ["user_id"], name: "index_radio_events_on_user_id"
  end

  create_table "radio_group_accesses", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "radio_group_id", null: false
    t.string "level", default: "operate", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["radio_group_id"], name: "index_radio_group_accesses_on_radio_group_id"
    t.index ["user_id", "radio_group_id"], name: "index_radio_group_accesses_on_user_id_and_radio_group_id", unique: true
    t.index ["user_id"], name: "index_radio_group_accesses_on_user_id"
  end

  create_table "radio_group_memberships", force: :cascade do |t|
    t.bigint "radio_group_id", null: false
    t.bigint "radio_id", null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["radio_group_id", "radio_id"], name: "index_radio_group_memberships_on_radio_group_id_and_radio_id", unique: true
    t.index ["radio_group_id"], name: "index_radio_group_memberships_on_radio_group_id"
    t.index ["radio_id"], name: "index_radio_group_memberships_on_radio_id"
  end

  create_table "radio_groups", force: :cascade do |t|
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_radio_groups_on_name", unique: true
  end

  create_table "radios", force: :cascade do |t|
    t.bigint "server_id", null: false
    t.string "node", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.boolean "active", default: true, null: false
    t.boolean "receiving", default: false, null: false
    t.boolean "transmitting", default: false, null: false
    t.string "transmitted_by"
    t.string "last_unit_identifier"
    t.string "last_decoder"
    t.jsonb "links", default: [], null: false
    t.datetime "receiving_since"
    t.datetime "last_activity_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "unit_identified_at"
    t.datetime "transmitting_since"
    t.bigint "ptt_user_id"
    t.datetime "ptt_at"
    t.bigint "transmitted_by_user_id"
    t.index ["ptt_user_id"], name: "index_radios_on_ptt_user_id"
    t.index ["server_id", "node"], name: "index_radios_on_server_id_and_node", unique: true
    t.index ["server_id"], name: "index_radios_on_server_id"
    t.index ["transmitted_by_user_id"], name: "index_radios_on_transmitted_by_user_id"
  end

  create_table "recordings", force: :cascade do |t|
    t.bigint "server_id", null: false
    t.bigint "radio_id"
    t.string "node", null: false
    t.string "link_id", null: false
    t.string "direction", null: false
    t.datetime "started_at", null: false
    t.decimal "duration", precision: 8, scale: 2, default: "0.0", null: false
    t.string "unit_identifier"
    t.string "other_node"
    t.string "decoder"
    t.string "remote_node"
    t.string "audio_path", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["decoder", "unit_identifier"], name: "index_recordings_on_decoder_and_unit_identifier"
    t.index ["radio_id"], name: "index_recordings_on_radio_id"
    t.index ["server_id", "link_id"], name: "index_recordings_on_server_id_and_link_id", unique: true
    t.index ["server_id"], name: "index_recordings_on_server_id"
    t.index ["started_at"], name: "index_recordings_on_started_at"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name", null: false
    t.string "permissions", default: [], null: false, array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_roles_on_name", unique: true
  end

  create_table "servers", force: :cascade do |t|
    t.string "name", null: false
    t.string "host", null: false
    t.boolean "local", default: false, null: false
    t.integer "ami_port", default: 5038, null: false
    t.string "ami_username", null: false
    t.string "ami_password", null: false
    t.integer "ssh_port", default: 22, null: false
    t.string "ssh_username"
    t.string "webrtc_url"
    t.string "archive_path", default: "/var/spool/asterisk/archive", null: false
    t.boolean "active", default: true, null: false
    t.boolean "online", default: false, null: false
    t.datetime "status_changed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "sip_username", default: "webconsole", null: false
    t.string "sip_password"
    t.string "console_secret"
    t.string "time_zone", default: "America/Argentina/Buenos_Aires", null: false
    t.boolean "ssh_sudo", default: false, null: false
    t.datetime "recordings_synced_at"
    t.string "recordings_sync_error"
    t.index ["name"], name: "index_servers_on_name", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "units", force: :cascade do |t|
    t.string "identifier", null: false
    t.string "decoder", null: false
    t.string "name", null: false
    t.string "person"
    t.string "fleet"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["decoder", "identifier"], name: "index_units_on_decoder_and_identifier", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address"
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name", default: "", null: false
    t.string "locale", default: "es", null: false
    t.bigint "role_id", null: false
    t.boolean "active", default: true, null: false
    t.string "username", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["role_id"], name: "index_users_on_role_id"
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "link_requests", "radios"
  add_foreign_key "link_requests", "users"
  add_foreign_key "radio_events", "radios"
  add_foreign_key "radio_events", "servers"
  add_foreign_key "radio_events", "users"
  add_foreign_key "radio_group_accesses", "radio_groups"
  add_foreign_key "radio_group_accesses", "users"
  add_foreign_key "radio_group_memberships", "radio_groups"
  add_foreign_key "radio_group_memberships", "radios"
  add_foreign_key "radios", "servers"
  add_foreign_key "radios", "users", column: "ptt_user_id"
  add_foreign_key "radios", "users", column: "transmitted_by_user_id"
  add_foreign_key "recordings", "radios"
  add_foreign_key "recordings", "servers"
  add_foreign_key "sessions", "users"
  add_foreign_key "users", "roles"
end

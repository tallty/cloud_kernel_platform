# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20151118173239) do

  create_table "auto_stations", force: :cascade do |t|
    t.string   "datetime",       limit: 255
    t.string   "sitenumber",     limit: 255
    t.string   "name",           limit: 255
    t.string   "tempe",          limit: 255
    t.string   "rain",           limit: 255
    t.string   "wind_direction", limit: 255
    t.string   "wind_speed",     limit: 255
    t.string   "visibility",     limit: 255
    t.string   "humi",           limit: 255
    t.string   "max_tempe",      limit: 255
    t.string   "min_tempe",      limit: 255
    t.string   "max_speed",      limit: 255
    t.string   "max_direction",  limit: 255
    t.string   "pressure",       limit: 255
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  create_table "community_warnings", force: :cascade do |t|
    t.datetime "publish_time"
    t.string   "warning_type", limit: 255
    t.string   "level",        limit: 255
    t.text     "content",      limit: 65535
    t.string   "unit",         limit: 255
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.string   "status",       limit: 255
  end

  add_index "community_warnings", ["publish_time"], name: "index_community_warnings_on_publish_time", using: :btree
  add_index "community_warnings", ["unit"], name: "index_community_warnings_on_unit", using: :btree
  add_index "community_warnings", ["warning_type"], name: "index_community_warnings_on_warning_type", using: :btree

  create_table "country_real_aqis", force: :cascade do |t|
    t.datetime "datetime"
    t.string   "area",              limit: 255
    t.string   "position_name",     limit: 255
    t.string   "station_code",      limit: 255
    t.string   "primary_pollutant", limit: 255
    t.string   "quality",           limit: 255
    t.float    "aqi",               limit: 24
    t.float    "co",                limit: 24
    t.float    "co_24h",            limit: 24
    t.float    "no2",               limit: 24
    t.float    "no2_24h",           limit: 24
    t.float    "o3",                limit: 24
    t.float    "o3_24h",            limit: 24
    t.float    "o3_8h",             limit: 24
    t.float    "o3_8h_24h",         limit: 24
    t.float    "pm10",              limit: 24
    t.float    "pm10_24h",          limit: 24
    t.float    "pm2_5",             limit: 24
    t.float    "pm2_5_24h",         limit: 24
    t.float    "so2",               limit: 24
    t.float    "so2_24h",           limit: 24
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

  add_index "country_real_aqis", ["datetime"], name: "index_country_real_aqis_on_datetime", using: :btree
  add_index "country_real_aqis", ["position_name"], name: "index_country_real_aqis_on_position_name", using: :btree

  create_table "health_weathers", force: :cascade do |t|
    t.string   "title",      limit: 255
    t.datetime "datetime"
    t.integer  "level",      limit: 4
    t.string   "desc",       limit: 255
    t.string   "info",       limit: 255
    t.string   "guide",      limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "health_weathers", ["datetime"], name: "index_health_weathers_on_datetime", using: :btree
  add_index "health_weathers", ["title"], name: "index_health_weathers_on_title", using: :btree

  create_table "nationwide_station_items", force: :cascade do |t|
    t.datetime "report_date"
    t.string   "sitenumber",            limit: 255
    t.string   "city_name",             limit: 255
    t.float    "tempe",                 limit: 24
    t.float    "rain",                  limit: 24
    t.float    "wind_direction",        limit: 24
    t.float    "wind_speed",            limit: 24
    t.float    "visibility",            limit: 24
    t.float    "pressure",              limit: 24
    t.float    "humi",                  limit: 24
    t.integer  "nationwide_station_id", limit: 4
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
  end

  add_index "nationwide_station_items", ["report_date"], name: "index_nationwide_station_items_on_report_date", using: :btree
  add_index "nationwide_station_items", ["sitenumber"], name: "index_nationwide_station_items_on_sitenumber", using: :btree

  create_table "nationwide_stations", force: :cascade do |t|
    t.datetime "report_date"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "nationwide_stations", ["report_date"], name: "index_nationwide_stations_on_report_date", using: :btree

  create_table "real_time_aqis", force: :cascade do |t|
    t.datetime "datetime"
    t.integer  "aqi",        limit: 4
    t.string   "level",      limit: 255
    t.string   "pripoll",    limit: 255
    t.string   "content",    limit: 255
    t.string   "measure",    limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "real_time_aqis", ["datetime"], name: "index_real_time_aqis_on_datetime", using: :btree

  create_table "short_time_reports", force: :cascade do |t|
    t.datetime "datetime"
    t.string   "promulgator",    limit: 255
    t.string   "report_type",    limit: 255
    t.text     "report_content", limit: 65535
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  add_index "short_time_reports", ["datetime"], name: "index_short_time_reports_on_datetime", using: :btree
  add_index "short_time_reports", ["promulgator"], name: "index_short_time_reports_on_promulgator", using: :btree

  create_table "stable_stations", force: :cascade do |t|
    t.datetime "datetime"
    t.string   "site_number",    limit: 255
    t.string   "site_name",      limit: 255
    t.float    "tempe",          limit: 24
    t.float    "rain",           limit: 24
    t.float    "humi",           limit: 24
    t.float    "air_press",      limit: 24
    t.float    "wind_direction", limit: 24
    t.float    "wind_speed",     limit: 24
    t.float    "vis",            limit: 24
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  add_index "stable_stations", ["datetime"], name: "index_stable_stations_on_datetime", using: :btree
  add_index "stable_stations", ["site_number"], name: "index_stable_stations_on_site_number", using: :btree

  create_table "station_infos", force: :cascade do |t|
    t.string   "name",        limit: 255
    t.string   "alias_name",  limit: 255
    t.string   "site_number", limit: 255
    t.string   "district",    limit: 255
    t.string   "address",     limit: 255
    t.float    "lon",         limit: 24
    t.float    "lat",         limit: 24
    t.float    "high",        limit: 24
    t.string   "province",    limit: 255
    t.string   "site_type",   limit: 255
    t.string   "subjection",  limit: 255
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  create_table "typhoon_items", force: :cascade do |t|
    t.string   "location",     limit: 255
    t.datetime "report_time"
    t.integer  "effective",    limit: 4
    t.float    "lon",          limit: 24
    t.float    "lat",          limit: 24
    t.float    "max_wind",     limit: 24
    t.float    "min_pressure", limit: 24
    t.float    "seven_radius", limit: 24
    t.float    "ten_radius",   limit: 24
    t.float    "direct",       limit: 24
    t.float    "speed",        limit: 24
    t.integer  "typhoon_id",   limit: 4
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  add_index "typhoon_items", ["effective"], name: "index_typhoon_items_on_effective", using: :btree
  add_index "typhoon_items", ["location"], name: "index_typhoon_items_on_location", using: :btree
  add_index "typhoon_items", ["typhoon_id"], name: "index_typhoon_items_on_typhoon_id", using: :btree

  create_table "typhoons", force: :cascade do |t|
    t.string   "name",             limit: 255
    t.string   "location",         limit: 255
    t.string   "cname",            limit: 255
    t.string   "ename",            limit: 255
    t.string   "data_info",        limit: 255
    t.datetime "last_report_time"
    t.integer  "year",             limit: 4
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  add_index "typhoons", ["location"], name: "index_typhoons_on_location", using: :btree
  add_index "typhoons", ["name"], name: "index_typhoons_on_name", using: :btree

  create_table "weather_reports", force: :cascade do |t|
    t.datetime "datetime"
    t.string   "promulgator", limit: 255
    t.string   "report_type", limit: 255
    t.text     "content",     limit: 65535
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "weather_reports", ["datetime"], name: "index_weather_reports_on_datetime", using: :btree
  add_index "weather_reports", ["report_type"], name: "index_weather_reports_on_report_type", using: :btree

end

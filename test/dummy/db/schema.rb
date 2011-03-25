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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110217062316) do

  create_table "mail_logs", :force => true do |t|
    t.string   "mail_template_path"
    t.string   "recipient"
    t.string   "sender"
    t.string   "subject"
    t.string   "mime_type"
    t.text     "raw_body"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "mail_schedules", :force => true do |t|
    t.string   "name"
    t.integer  "mail_template_id"
    t.string   "user_group"
    t.integer  "count",            :default => 0
    t.integer  "sent_count",       :default => 0
    t.string   "period"
    t.string   "payload"
    t.datetime "first_send_at"
    t.datetime "last_sent_at"
    t.boolean  "available"
    t.string   "default_locale"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "mail_template_files", :force => true do |t|
    t.integer  "mail_template_id"
    t.string   "file"
    t.integer  "size"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "mail_templates", :force => true do |t|
    t.string   "name"
    t.string   "subject"
    t.string   "path"
    t.string   "format",        :default => "html"
    t.string   "locale"
    t.string   "handler",       :default => "liquid"
    t.text     "body"
    t.boolean  "partial",       :default => false
    t.boolean  "for_marketing", :default => false
    t.string   "layout",        :default => "none"
    t.string   "zip_file"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "template_partials", :force => true do |t|
    t.string  "placeholder_name"
    t.integer "mail_template_id"
    t.integer "partial_id"
  end

  create_table "users", :force => true do |t|
    t.string   "email"
    t.string   "locale",     :default => "en"
    t.string   "firstname"
    t.string   "lastname"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end

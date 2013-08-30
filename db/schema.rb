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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130829142607) do

  create_table "orders", :force => true do |t|
    t.string   "email"
    t.string   "comment"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.integer  "theme_id"
  end

  create_table "themes", :force => true do |t|
    t.integer  "template_monster_id"
    t.integer  "price"
    t.string   "screenshot_list"
    t.integer  "authors_id"
    t.string   "keywords_list"
    t.string   "categories_list"
    t.string   "sources"
    t.string   "type"
    t.string   "description"
    t.string   "pages"
    t.datetime "created_at",          :null => false
    t.datetime "updated_at",          :null => false
    t.integer  "exclusive_price"
    t.integer  "active"
    t.datetime "date_of_addition"
  end

end

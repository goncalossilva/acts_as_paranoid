require 'rubygems'
require 'test/unit'
require 'active_support'
require 'active_record'
require 'active_model'

$:.unshift "#{File.dirname(__FILE__)}/../"
$:.unshift "#{File.dirname(__FILE__)}/../lib/"
$:.unshift "#{File.dirname(__FILE__)}/../lib/validations"

require 'init'

ActiveRecord::Base.establish_connection(:adapter => "mysql2", :database => ":memory:")

def setup_db
  ActiveRecord::Schema.define(:version => 1) do
    create_table "blogs", :force => true do |t|
    t.string   "title"
    t.string   "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.string   "exclusion_cd"
    t.time     "deleted_at"
  end

  create_table "comments", :force => true do |t|
    t.string   "comment"
    t.string   "author"
    t.integer  "blogs_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "name"
    t.string   "email"
    t.string   "userid"
    t.string   "pwd"
    t.integer  "no_of_blogs"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "password_salt"
    t.string   "password_hash"
    t.string   "exclusion_cd"
    t.time     "deleted_at"
  end
  end
end

def teardown_db
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
end



class Blog < ActiveRecord::Base
	acts_as_paranoid
end
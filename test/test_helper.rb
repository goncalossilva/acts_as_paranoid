require 'rubygems'
require 'test/unit'
require 'active_support'
require 'active_record'

$:.unshift "#{File.dirname(__FILE__)}/../lib/"
require 'rails3_acts_as_paranoid'

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")

def setup_db
  ActiveRecord::Schema.define(:version => 1) do
    create_table :paranoid_times do |t|
      t.string :name
      t.datetime :deleted_at
    end

    create_table :paranoid_booleans do |t|
      t.string :name
      t.boolean :is_deleted
    end

    create_table :not_paranoids do |t|
      t.string :name
    end
    
    create_table :blogs do |t|
      t.string :name
      t.datetime :deleted_at, :datetime
    end

    create_table :companies do |t|
      t.string :name
      t.datetime :deleted_at
    end
    
    create_table :products do |t|
      t.references :company
      t.string :name
      t.datetime :deleted_at
    end
  end
end

def teardown_db
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
end

class ParanoidTime < ActiveRecord::Base
  acts_as_paranoid
end

class ParanoidBoolean < ActiveRecord::Base
  acts_as_paranoid :column_type => "boolean", :column => "is_deleted"
end

class NotParanoid < ActiveRecord::Base
end

class Company < ActiveRecord::Base
  acts_as_paranoid
  validates :name, :presence => true
  has_many :products, :dependent => :destroy
end

class Product < ActiveRecord::Base
  acts_as_paranoid
  belongs_to :company
  validates_presence_of :company, :name
end

module ActsAsParanoid
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      
      desc "Makes a model paranoid"
      
      argument  :paranoid_model,  :type => :string, :desc => "Model to make paranoid"
      
      class_option :column,       :type => :string, :default => 'deleted_at', :desc => "Column that stores the model's deleted status"
      class_option :column_type,  :type => :string, :default => 'time',       :desc => "Column type must be either time, boolean, or string"
      
      source_root File.expand_path("../templates", __FILE__)
      
      def self.next_migration_number(dirname)
        Time.now.strftime("%Y%m%d%H%M%S")
      end
    
      def add_acts_as_paranoid
        valid_column_type?
        
        if File.exist?(model_filename)
          inject_into_file model_filename, :after => "class #{model} < ActiveRecord::Base" do
            %Q{
  acts_as_paranoid :column => '#{column}', :column_type => '#{column_type}'
            }
          end
        else
          template "model.rb.erb", model_filename
        end
      end
      
      def create_migration        
        migration_name = "add_acts_as_paranoid_to_#{model.underscore}"
        migration_template "add_acts_as_paranoid_to_model.rb.erb", "db/migrate/#{migration_name}"
      end
      
      protected
      
      def column
        options[:column].to_s
      end
      
      def column_type
        options[:column_type].to_s
      end
      
      def model
        paranoid_model.classify
      end
      
      def model_filename
        "app/models/#{model.underscore}.rb"
      end
      
      def valid_column_type?
        raise ArgumentError, "Invalid column_type: #{column_type}" unless ['boolean', 'time', 'string'].include?(column_type)
      end
    end
  end
end
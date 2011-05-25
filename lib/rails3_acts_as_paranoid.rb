require 'active_record'
require 'validations/uniqueness_without_deleted'

module ActsAsParanoid
  
  def paranoid?
    self.included_modules.include?(InstanceMethods)
  end
  
  def validates_as_paranoid
    extend ParanoidValidations::ClassMethods
  end
  
  def acts_as_paranoid(options = {})
    raise ArgumentError, "Hash expected, got #{options.class.name}" if not options.is_a?(Hash) and not options.empty?
    
    class_attribute :paranoid_configuration, :paranoid_column_reference
    
    self.paranoid_configuration = { :column => "deleted_at", :column_type => "time", :recover_dependent_associations => true, :dependent_recovery_window => 5.minutes }.merge(options)

    raise ArgumentError, "'time' or 'boolean' expected for :column_type option, got #{paranoid_configuration[:column_type]}" unless ['time', 'boolean'].include? paranoid_configuration[:column_type]

    self.paranoid_column_reference = "#{self.table_name}.#{paranoid_configuration[:column]}"
    
    return if paranoid?

    ActiveRecord::Relation.class_eval do
      alias_method :delete_all!, :delete_all
      alias_method :destroy!, :destroy
    end
    
    default_scope where("#{paranoid_column_reference} IS ?", nil) # Magic!
    
    scope :paranoid_deleted_around_time, lambda {|value, window|
      if self.class.respond_to?(:paranoid?) && self.class.paranoid?
        if self.class.paranoid_column_type == 'time' && ![true, false].include?(value)
          self.where("#{self.class.paranoid_column} > ? AND #{self.class.paranoid_column} < ?", (value - window), (value + window))
        else
          self.only_deleted
        end
      end
    }
    
    include InstanceMethods
    extend ClassMethods
  end

  module ClassMethods
    
    def with_deleted
      self.unscoped.reload
    end

    def only_deleted
      self.unscoped.where("#{paranoid_column_reference} IS NOT ?", nil)
    end

    def delete_all!(conditions = nil)
      self.unscoped.delete_all!(conditions)
    end

    def delete_all(conditions = nil)
      update_all ["#{paranoid_configuration[:column]} = ?", delete_now_value], conditions
    end

    def paranoid_column
      paranoid_configuration[:column].to_sym
    end

    def paranoid_column_type
      paranoid_configuration[:column_type].to_sym
    end

    def dependent_associations
      self.reflect_on_all_associations.select {|a| [:delete_all, :destroy].include?(a.options[:dependent]) }
    end
  
    def delete_now_value
      case paranoid_configuration[:column_type]
        when "time" then Time.now
        when "boolean" then true
      end
    end
  end
  
  module InstanceMethods
    
    def paranoid_value
      self.send(self.class.paranoid_column)
    end
  
    def destroy!
      with_transaction_returning_status do
        run_callbacks :destroy do
          self.class.delete_all!(:id => self.id)
          self.paranoid_value = self.class.delete_now_value
          freeze
        end
      end
    end

    def destroy
      with_transaction_returning_status do
        run_callbacks :destroy do
          if paranoid_value.nil?
            self.class.delete_all(:id => self.id)
          else
            self.class.delete_all!(:id => self.id)
          end
          self.paranoid_value = self.class.delete_now_value
        end
      end
    end
    
    def recover(options={})
      options = {
                  :recursive => self.class.paranoid_configuration[:recover_dependent_associations],
                  :recovery_window => self.class.paranoid_configuration[:dependent_recovery_window]
                }.merge(options)

      self.class.transaction do
        recover_dependent_associations(options[:recovery_window], options) if options[:recursive]

        self.update_attributes(self.class.paranoid_column.to_sym => nil)
      end
    end

    def recover_dependent_associations(window, options)
      self.class.dependent_associations.each do |association|
        if association.collection? && self.send(association.name).paranoid?
          self.send(association.name).unscoped do
            self.send(association.name).paranoid_deleted_around_time(paranoid_value, window).each do |object|
              object.recover(options) if object.respond_to?(:recover)
            end
          end
        elsif association.macro == :has_one && association.klass.paranoid?
          association.klass.unscoped do
            object = association.klass.paranoid_deleted_around_time(paranoid_value, window).send('find_by_'+association.primary_key_name, self.id)
            object.recover(options) if object && object.respond_to?(:recover)
          end
        elsif association.klass.paranoid?
          association.klass.unscoped do
            id = self.send(association.primary_key_name)
            object = association.klass.paranoid_deleted_around_time(paranoid_value, window).find_by_id(id)
            object.recover(options) if object && object.respond_to?(:recover)
          end
        end
      end
    end

    def deleted?
      !paranoid_value.nil?
    end
    alias_method :destroyed?, :deleted?
    
  private
    def paranoid_value=(value)
      self.send("#{self.class.paranoid_column}=", value)
    end
    
  end
  
end

# Extend ActiveRecord's functionality
ActiveRecord::Base.send :extend, ActsAsParanoid

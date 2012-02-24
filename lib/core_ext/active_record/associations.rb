module ActiveRecord
  module Associations
    module ClassMethods
      @@valid_keys_for_belongs_to_association << :with_deleted
    end

    class BelongsToAssociation < AssociationProxy 
      def find_target
        find_method = if @reflection.options[:primary_key]
                        "find_by_#{@reflection.options[:primary_key]}"
                      else
                        "find"
                      end

        options = @reflection.options.dup

        (options.keys - [:select, :include, :readonly, :with_deleted]).each do |key|
          options.delete key
        end
        puts options.inspect
        options[:conditions] = conditions

        if( @owner[@reflection.primary_key_name] )
          the_target = options.delete(:with_deleted) ? @reflection.klass.send(:unscoped) : @reflection.klass
          the_target = the_target.send(
            find_method,
            @owner[@reflection.primary_key_name],
            options
          )
        end
        set_inverse_instance(the_target, @owner)

        the_target
      end
    end
  end
end

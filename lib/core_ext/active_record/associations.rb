module ActiveRecord
  module Associations
    module ClassMethods
      @@valid_keys_for_belongs_to_association << :with_deleted
    end
  end
end

module ActsAsParanoid

  class BelongsToWithDeletedAssociation < ActiveRecord::Associations::BelongsToAssociation
    private
    def find_target
      @reflection.klass.find_with_deleted(
        @owner[@reflection.primary_key_name],
        :conditions => conditions, 
        :include => @reflection.options[:include]
      )
    end
  end
end

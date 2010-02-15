module RedmineExtraLdap
  module Patches
    module UserPatch
      def self.included(base)
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)
      end

      module ClassMethods
        def create_from_ldap(attributes={})
          create(attributes) do |user|
            user.login = attributes[:login]
          end
        end
      end

      module InstanceMethods
      end
    end
  end
end

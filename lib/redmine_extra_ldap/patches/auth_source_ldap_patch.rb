module RedmineExtraLdap
  module Patches
    module AuthSourceLdapPatch
      def self.included(base)
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)
      end

      module ClassMethods
        def supports_failover?
          AuthSourceLdap.columns.collect(&:name).include?("failover_host")
        end
      end

      module InstanceMethods
        # TODO: Refactor the Redmine core so these can be reused
        # instead of copied
        def add_new_users(options={})
          ldap_con = initialize_ldap_con(self.account, self.account_password)
          object_filter = Net::LDAP::Filter.eq( "objectClass", "*" )
          # Handle new code for custom LDAP filters
          if respond_to?(:custom_filter)
            custom_ldap_filter = custom_filter_to_ldap
          end

          if custom_ldap_filter.present?
            search_filters = object_filter & custom_ldap_filter
          else
            search_filters = object_filter
          end

          dn = String.new
          attrs = []

          if group_id = options[:group]
            group = Group.find_by_id(group_id)
            group ||= Group.find_by_lastname(group_id)
          end

          ldap_con.search( :base => self.base_dn, 
                           :filter => search_filters,
                           :attributes=> ['dn',
                                          self.attr_login,
                                          self.attr_firstname,
                                          self.attr_lastname,
                                          self.attr_mail]) do |entry|
            attrs = [:firstname => AuthSourceLdap.get_attr(entry, self.attr_firstname),
                     :lastname => AuthSourceLdap.get_attr(entry, self.attr_lastname),
                     :mail => AuthSourceLdap.get_attr(entry, self.attr_mail),
                     :auth_source_id => self.id ]
            new_user = User.create(*attrs) do |user|
              user.login = AuthSourceLdap.get_attr(entry, self.attr_login)
            end

            if new_user.valid?
              new_user.groups << group if group.present?
              new_user.groups << self.groups if self.respond_to?(:groups) && self.groups
            end

          end
        rescue Net::LDAP::LdapError => text
          if self.class.supports_failover? && allow_failover? && !failover_triggered?
            try_to_failover_and_log
            retry
          else
            raise "LdapError: " + text
          end
        end

        # Connects to LDAP and returns the configured custom user
        # attributes for the use with login
        def get_custom_attributes_for_user(login)
          ldap_con = initialize_ldap_con(self.account, self.account_password)
          object_filter = Net::LDAP::Filter.eq( "objectClass", "*" )
          login_filter = Net::LDAP::Filter.eq( self.attr_login, login ) 

          attrs = []

          # Handle new code for custom LDAP filters
          if respond_to?(:custom_filter)
            custom_ldap_filter = custom_filter_to_ldap
          end

          if custom_ldap_filter.present?
            search_filters = object_filter & login_filter & custom_ldap_filter
          else
            search_filters = object_filter & login_filter
          end

          ldap_con.search( :base => self.base_dn, 
                           :filter => search_filters,
                           :attributes=> ['dn',
                                          custom_attributes.values]) do |entry|
            attrs = get_user_attributes_from_ldap_entry(entry)
          end

          return attrs

        rescue Net::LDAP::LdapError => text
          if self.class.supports_failover? && allow_failover? && !failover_triggered?
            try_to_failover_and_log
            retry
          else
            raise "LdapError: " + text
          end

        end

        def user_exists?(user)
          # get user's DN
          ldap_con = initialize_ldap_con(self.account, self.account_password)
          login_filter = Net::LDAP::Filter.eq( self.attr_login, user.login )
          object_filter = Net::LDAP::Filter.eq( "objectClass", "*" )
          # Handle new code for custom LDAP filters
          if respond_to?(:custom_filter)
            custom_ldap_filter = custom_filter_to_ldap
          end

          if custom_ldap_filter.present?
            search_filters = object_filter & login_filter & custom_ldap_filter
          else
            search_filters = object_filter & login_filter
          end

          dn = String.new
          ldap_con.search( :base => self.base_dn, 
                           :filter => search_filters,
                           :attributes=> ['dn']) do |entry|
            dn = entry.dn
          end
          
          return dn.present?

        rescue Net::LDAP::LdapError => text
          if self.class.supports_failover? && allow_failover? && !failover_triggered?
            try_to_failover_and_log
            retry
          else
            raise "LdapError: " + text
          end
        end

        def find_user_by_email(mail)
          dn = String.new
          attrs = []

          ldap_con = initialize_ldap_con(self.account, self.account_password)
          mail_filter = Net::LDAP::Filter.eq( self.attr_mail, mail ) 
          object_filter = Net::LDAP::Filter.eq( "objectClass", "*" )

          ldap_con.search( :base => base_dn,
                           :filter => object_filter & mail_filter,
                           :attributes => ['dn',
                                           attr_login,
                                           attr_firstname,
                                           attr_lastname,
                                           attr_mail]) do |entry|
            attrs = [:login => AuthSourceLdap.get_attr(entry, self.attr_login),
                     :firstname => AuthSourceLdap.get_attr(entry, self.attr_firstname),
                     :lastname => AuthSourceLdap.get_attr(entry, self.attr_lastname),
                     :mail => AuthSourceLdap.get_attr(entry, self.attr_mail),
                     :auth_source_id => self.id ]
            
            dn = entry.dn
          end

          if dn.empty?
            return false
          else
            return attrs
          end
        rescue Net::LDAP::LdapError => text
          if self.class.supports_failover? && allow_failover? && !failover_triggered?
            try_to_failover_and_log
            retry
          else
            raise "LdapError: " + text
          end

        end
      end
    end
  end
end


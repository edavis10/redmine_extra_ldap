module RedmineExtraLdap
  module Patches
    module AuthSourceLdapPatch
      def self.included(base)
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)
      end

      module ClassMethods
      end

      module InstanceMethods
        # TODO: Refactor the Redmine core so these can be reused
        # instead of copied
        def add_new_users(options={})
          ldap_con = initialize_ldap_con(self.account, self.account_password)
          object_filter = Net::LDAP::Filter.eq( "objectClass", "*" ) 
          dn = String.new
          attrs = []

          if group_id = options[:group]
            group = Group.find_by_id(group_id)
            group ||= Group.find_by_lastname(group_id)
          end

          ldap_con.search( :base => self.base_dn, 
                           :filter => object_filter,
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
        end

        def user_exists?(user)
          # get user's DN
          ldap_con = initialize_ldap_con(self.account, self.account_password)
          login_filter = Net::LDAP::Filter.eq( self.attr_login, user.login )
          object_filter = Net::LDAP::Filter.eq( "objectClass", "*" )
          dn = String.new
          ldap_con.search( :base => self.base_dn, 
                           :filter => object_filter & login_filter, 
                           :attributes=> ['dn']) do |entry|
            dn = entry.dn
          end
          
          return dn.present?

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
        end
      end
    end
  end
end


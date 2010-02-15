require 'redmine'

Redmine::Plugin.register :redmine_extra_ldap do
  name 'Redmine Extra Ldap plugin'
  author 'Author name'
  description 'This is a plugin for Redmine'
  version '0.0.1'
end

# Patches to the Redmine core.
require 'dispatcher'

Dispatcher.to_prepare :redmine_extra_ldap do
  require_dependency 'auth_source'
  require_dependency 'auth_source_ldap'
  AuthSourceLdap.send(:include, RedmineExtraLdap::Patches::AuthSourceLdapPatch)
  require_dependency 'principal'
  require_dependency 'user'
  User.send(:include, RedmineExtraLdap::Patches::UserPatch)
end

require 'redmine_extra_ldap/hooks/auth_sources_hooks'
require 'redmine_extra_ldap/hooks/mail_handler_hooks'


def extract_ldap_source
  ENV['USE'] || ENV['use']
end

namespace :extra_ldap do
  desc <<-END_DESC
Query LDAP and add any missing users to Redmine.

Required Options:
  use=connection-name    name or id of a Redmine LDAP source to check. (Use ALL for all connections)

Options:
  group=GROUP            name or id of a Redmine group to add the user to
END_DESC

  task :add_new_users => :environment do
    group = ENV['group']
    group ||= ENV['GROUP']
    ExtraLdap.add_new_users(extract_ldap_source, group)
  end

  desc <<-END_DESC
Add any existing users who are not in a group so a specific group.

Required Options:
  use=connection-name    name or id of a Redmine LDAP source to check. (Use ALL for all connections)

Options:
  group=GROUP            name or id of a Redmine group to add the user to
END_DESC

  task :add_existing_users_to_default_group => :environment do
    group = ENV['group']
    group ||= ENV['GROUP']
    ExtraLdap.add_existing_users_to_default_group(extract_ldap_source, group)
  end

  desc <<-END_DESC
Lock (or unlock) users who are not found (or found) in the LDAP database.

Required Options:
  use=connection-name    name or id of a Redmine LDAP source to check. (Use ALL for all connections)

END_DESC

  task :lock_or_unlock_accounts => :environment do
    ExtraLdap.lock_or_unlock_accounts(extract_ldap_source)
  end

  desc <<-END_DESC
Update the custom data fields for LDAP users.

Required Options:
  use=connection-name    name or id of a Redmine LDAP source to check. (Use ALL for all connections)

END_DESC

  task :update_custom_user_data => :environment do
    ExtraLdap.update_custom_user_data(extract_ldap_source)
  end
end

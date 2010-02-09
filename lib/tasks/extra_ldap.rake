namespace :extra_ldap do
  desc <<-END_DESC
Query LDAP and add any missing users to Redmine.

Options:
  group=GROUP            name or id of a Redmine group to add the user to
END_DESC

  task :add_new_users => :environment do
    group = ENV['group']
    ExtraLdap.add_new_users(group)
  end

  desc <<-END_DESC
Add any existing users who are not in a group so a specific group.

Options:
  group=GROUP            name or id of a Redmine group to add the user to
END_DESC

  task :add_existing_users_to_default_group => :environment do
    group = ENV['group']
    ExtraLdap.add_existing_users_to_default_group(group)
  end

  desc <<-END_DESC
Lock (or unlock) users who are not found (or found) in the LDAP database.

END_DESC

  task :lock_or_unlock_accounts => :environment do
    ExtraLdap.lock_or_unlock_accounts
  end
end

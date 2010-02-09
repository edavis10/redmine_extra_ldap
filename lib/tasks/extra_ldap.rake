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
end

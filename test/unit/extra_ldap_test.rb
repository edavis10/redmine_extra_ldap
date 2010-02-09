require File.dirname(__FILE__) + '/../test_helper'

class ExtraLdapTest < ActiveSupport::TestCase
  context '#add_new_users' do
    context 'without an active LDAP connection' do
      should 'not change the user count' do
        assert_difference('User.count',0) do
          ExtraLdap.add_new_users
        end
      end
    end

    context 'with active LDAP connections' do
      setup do
        # Two users
        @auth1 = AuthSourceLdap.generate!(:name => 'localhost',
                                          :host => '127.0.0.1',
                                          :port => 389,
                                          :base_dn => 'OU=Person,DC=redmine,DC=org',
                                          :attr_login => 'uid',
                                          :attr_firstname => 'givenName',
                                          :attr_lastname => 'sn',
                                          :attr_mail => 'mail')
        # Four users, one duplicate
        @auth2 = AuthSourceLdap.generate!(:name => 'localhost database 2',
                                          :host => '127.0.0.1',
                                          :port => 389,
                                          :base_dn => 'OU=Person,DC=redmine2,DC=org',
                                          :attr_login => 'uid',
                                          :attr_firstname => 'givenName',
                                          :attr_lastname => 'sn',
                                          :attr_mail => 'mail')

      end
      
      should 'add each new user to Redmine' do
        assert_difference('User.count', 5) do
          ExtraLdap.add_new_users
        end
      end

      should 'allow each new user to login against LDAP' do
        ExtraLdap.add_new_users

        ['example1','edavis','another1','edavis0','edavis1'].each do |login|
          assert User.try_to_login(login, '123456')
        end
      end

      context 'and a group parameter' do
        setup do
          @group = Group.generate!
        end

        should 'add each user to the specific Redmine group using the group id' do
          assert_difference('@group.users.count', 5) do
            ExtraLdap.add_new_users(@group.id)
          end
        end
        
        should 'allow using the name for the group using the group name' do
          assert_difference('@group.users.count', 5) do
            ExtraLdap.add_new_users(@group.lastname)
          end
        end
      end
    end
      
  end

  context '#add_existing_users_to_default_group' do
    context 'no group parameter' do
      should 'raise an error' do
        assert_raises ArgumentError do
          ExtraLdap.add_existing_users_to_default_group(nil)
        end
      end
    end

    context 'with an invalid group id or name' do
      should 'raise an error' do
        assert_raises ArgumentError do
          ExtraLdap.add_existing_users_to_default_group('not a real group')
        end
      end
    end

    context 'with a valid group' do
      setup do
        @group_parameter = Group.generate!(:lastname => 'new group')
        @existing_group = Group.generate!(:lastname => 'existing group')
        
        @no_group_user1 = User.generate_with_protected!
        @no_group_user2 = User.generate_with_protected!
        @existing_group_user = User.generate_with_protected!
        @existing_group_user.groups << @existing_group
      end

      should 'add users without a group to the group parameter' do
        ExtraLdap.add_existing_users_to_default_group(@group_parameter.id)

        assert @no_group_user1.groups.include?(@group_parameter), "User1 did not join the group"
        assert @no_group_user2.groups.include?(@group_parameter), "User2 did not join the group"
      end

      should 'not add users who are already in a group' do
        ExtraLdap.add_existing_users_to_default_group(@group_parameter.id)

        assert !@existing_group_user.group_ids.include?(@group_parameter.id), "User on another group was incorrected added"
      end

      should 'also allow a group name' do
        ExtraLdap.add_existing_users_to_default_group(@group_parameter.lastname)

        assert @no_group_user1.groups.include?(@group_parameter), "User1 did not join the group"
        assert @no_group_user2.groups.include?(@group_parameter), "User2 did not join the group"
      end

    end
  end

end

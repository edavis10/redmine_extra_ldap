require File.dirname(__FILE__) + '/../test_helper'

class ExtraLdapTest < ActiveSupport::TestCase
  context '#add_new_users' do
    context 'without an active LDAP connection' do
      should 'raise an error' do
        assert_raises ArgumentError do
          ExtraLdap.add_new_users('some ldap')
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
        assert_difference('User.count', 2) do
          ExtraLdap.add_new_users(@auth1.name)
        end
      end

      should 'allow each new user to login against LDAP' do
        ExtraLdap.add_new_users(@auth1.name)
        ExtraLdap.add_new_users(@auth2.name)
        
        ['example1','edavis','another1','edavis0','edavis1'].each do |login|
          assert User.try_to_login(login, '123456'), "Login failed for #{login}"
        end
      end

      context 'and a group parameter' do
        setup do
          @group = Group.generate!
        end

        should 'add each user to the specific Redmine group using the group id' do
          assert_difference('@group.users.count', 5) do
            ExtraLdap.add_new_users(@auth1.name, @group.id)
            ExtraLdap.add_new_users(@auth2.name, @group.id)
          end
        end
        
        should 'allow using the name for the group using the group name' do
          assert_difference('@group.users.count', 5) do
            ExtraLdap.add_new_users(@auth1.name, @group.lastname)
            ExtraLdap.add_new_users(@auth2.name, @group.lastname)
          end
        end
      end

      context 'with groups associated to the LDAP Auth Source' do
        setup do
          @group = Group.generate!
          @auth1.groups << @group
        end

        should "add the Auth Source's groups to the user" do
          assert_difference('@group.users.count',2) do
            ExtraLdap.add_new_users(@auth1.name)
          end
          
          user = User.find_by_login('edavis')
          assert user
          assert user.groups.include?(@group), "User did not join the group"

        end
      end

      context 'with the "ALL" ldap connection name' do
        should 'connect to all of the LDAP connections to add new users' do
          assert_difference('User.count', 5) do
            ExtraLdap.add_new_users('all')
          end
        end
      end

      context 'with a custom_filter' do
        should 'only add users matching the custom_filter' do
          @auth1.update_attributes(:custom_filter => "(& (homeDirectory=*) (sn=O*))")
          @auth1.reload

          assert_difference('User.count', 1) do
            ExtraLdap.add_new_users(@auth1.name)
          end

          assert !User.try_to_login('edavis', '123456')
          assert User.try_to_login('example1', '123456')

        end
      end
      
    end
      
  end

  context '#lock_or_unlock_accounts' do
    context 'without an LDAP connection' do
      should 'raise an error' do
        assert_raises ArgumentError do
          ExtraLdap.lock_or_unlock_accounts('some name')
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

        # Add all of the users from LDAP
        ExtraLdap.add_new_users(@auth1.name)
      end
        
      context "with an active user" do
        should "lock their account if they are not found in their AuthSource" do
          @active_and_missing_user = User.generate_with_protected!(:auth_source => @auth1)
          assert !@active_and_missing_user.locked?
          
          ExtraLdap.lock_or_unlock_accounts(@auth1.id)

          assert @active_and_missing_user.reload.locked?
        end
      end
      context "with a locked user" do
        should "unlock their account if they are found in the AuthSource" do
          User.destroy_all({:login => 'edavis'})
          @locked_and_present_user = User.generate_with_protected!(:auth_source => @auth1, :login => 'edavis', :status => User::STATUS_LOCKED)
          assert @locked_and_present_user.locked?
          
          ExtraLdap.lock_or_unlock_accounts(@auth1.id)

          assert !@locked_and_present_user.reload.locked?
        end
      end

      context 'with a custom_filter on AuthSourceLdap' do
        should 'make sure the custom_filter is used' do
          @auth1.update_attributes(:custom_filter => "(& (homeDirectory=*) (sn=O*))")
          @auth1.reload

          ExtraLdap.lock_or_unlock_accounts(@auth1.id)

          assert User.find_by_login('edavis').locked?, "user not found due to a custom_filter was not locked"
          assert User.find_by_login('example1').active?, "user found with a custom_filter was locked"

        end
      end


      context 'with the "ALL" ldap connection name' do
        should 'connect to all of the LDAP connections to add new users' do
          @active_and_missing_user = User.generate_with_protected!(:auth_source => @auth1)
          assert !@active_and_missing_user.locked?
          
          ExtraLdap.lock_or_unlock_accounts('all')

          assert @active_and_missing_user.reload.locked?
        end
      end

    end
  end

  context '#add_existing_users_to_default_group' do
    context 'no group parameter' do
      should 'raise an error' do
        assert_raises ArgumentError do
          ExtraLdap.add_existing_users_to_default_group('',nil)
        end
      end
    end

    context 'with an invalid group id or name' do
      should 'raise an error' do
        assert_raises ArgumentError do
          ExtraLdap.add_existing_users_to_default_group('','not a real group')
        end
      end
    end

    context 'with an empty ldap id or name' do
      should 'raise an error' do
        assert_raises ArgumentError do
          group = Group.generate!(:lastname => 'new group')
          ExtraLdap.add_existing_users_to_default_group(nil, group.lastname)
        end
      end
    end

    context 'with an invalid ldap id or name' do
      should 'raise an error' do
        assert_raises ArgumentError do
          group = Group.generate!(:lastname => 'new group')
          ExtraLdap.add_existing_users_to_default_group('ponies', group.lastname)
        end
      end
    end

    context 'with a valid group' do
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

        @group_parameter = Group.generate!(:lastname => 'new group')
        @existing_group = Group.generate!(:lastname => 'existing group')
        
        @no_group_user1 = User.generate_with_protected!(:auth_source_id => @auth1.id)
        @no_group_user2 = User.generate_with_protected!(:auth_source_id => @auth1.id)
        @existing_group_user = User.generate_with_protected!(:auth_source_id => @auth1.id)
        @existing_group_user.groups << @existing_group
      end

      should 'add users without a group to the group parameter' do
        ExtraLdap.add_existing_users_to_default_group(@auth1.name, @group_parameter.id)

        assert @no_group_user1.groups.include?(@group_parameter), "User1 did not join the group"
        assert @no_group_user2.groups.include?(@group_parameter), "User2 did not join the group"
      end

      should 'not add users who are already in a group' do
        ExtraLdap.add_existing_users_to_default_group(@auth1.name, @group_parameter.id)

        assert !@existing_group_user.group_ids.include?(@group_parameter.id), "User on another group was incorrected added"
      end

      should 'also allow a group name' do
        ExtraLdap.add_existing_users_to_default_group(@auth1.name, @group_parameter.lastname)

        assert @no_group_user1.groups.include?(@group_parameter), "User1 did not join the group"
        assert @no_group_user2.groups.include?(@group_parameter), "User2 did not join the group"
      end

      context 'with the "ALL" ldap connection name' do
        should 'connect to all of the LDAP connections to assign groups' do
          ExtraLdap.add_existing_users_to_default_group('all', @group_parameter.lastname)
          
          ExtraLdap.lock_or_unlock_accounts('all')
          assert @no_group_user1.groups.include?(@group_parameter), "User1 did not join the group"
          assert @no_group_user2.groups.include?(@group_parameter), "User2 did not join the group"
        end
      end


    end
  end

  context "#update_custom_user_data" do
    context 'without an active LDAP connection' do
      should 'raise an error' do
        assert_raises ArgumentError do
          ExtraLdap.update_custom_user_data('some ldap')
        end
      end
    end

    context 'with an active LDAP connection' do
      setup do
        @custom_field = UserCustomField.generate!(:name => 'Home directory')

        # Two users
        @auth1 = AuthSourceLdap.generate!(:name => 'localhost',
                                          :host => '127.0.0.1',
                                          :port => 389,
                                          :base_dn => 'OU=Person,DC=redmine,DC=org',
                                          :attr_login => 'uid',
                                          :attr_firstname => 'givenName',
                                          :attr_lastname => 'sn',
                                          :attr_mail => 'mail')

        # Add all of the users from LDAP
        ExtraLdap.add_new_users(@auth1.name)
        @user = User.find_by_login('example1')
        assert @user
        assert_equal @auth1, @user.auth_source
      end
      
      context 'that has no custom_attributes' do
        should 'do nothing to the user accounts' do
          ExtraLdap.update_custom_user_data(@auth1.name)

          assert_equal nil, @user.custom_value_for(@custom_field).value
        end

      end

      context 'that has custom_attributes configured' do
        should 'update the custom attribute values on the user' do
          @auth1.custom_attributes = {@custom_field.id.to_s => 'homeDirectory'}
          @auth1.save
          
          ExtraLdap.update_custom_user_data(@auth1.name)

          assert_equal '/home/example1', @user.custom_value_for(@custom_field).value
        end

      end
    end
  end
end

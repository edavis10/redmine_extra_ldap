require File.dirname(__FILE__) + '/../../../../test_helper'

class RedmineExtraLdap::Hook::MailHandlerHooksTest < ActiveSupport::TestCase
  include Redmine::Hook::Helper

  context "#model_mail_handler_find_user" do
    setup do
      @handler = MailHandler
      @standard_email_address = 'example1@redmine.org'
      AuthSourceLdap.delete_all
      User.delete_all
    end

    should 'do nothing to user if it is already set' do
      user = User.generate_with_protected!(:mail => @standard_email_address)
      returned_user = @handler.send(:find_user, @standard_email_address)

      assert_equal user, returned_user
    end
    
    context "with no on-the-fly AuthSources defined" do
      should 'do nothing to user' do
        AuthSourceLdap.generate!(:name => 'not on the fly',
                                 :host => '127.0.0.1',
                                 :port => 389,
                                 :base_dn => 'OU=Person,DC=redmine,DC=org',
                                 :attr_login => 'uid',
                                 :attr_firstname => 'givenName',
                                 :attr_lastname => 'sn',
                                 :attr_mail => 'mail')

        returned_user = @handler.send(:find_user, @standard_email_address)

        assert_equal nil, returned_user
      end
    end

    context "with on-the-fly AuthSources defined" do
      setup do
        AuthSourceLdap.generate!(:name => 'on the fly',
                                 :host => '127.0.0.1',
                                 :port => 389,
                                 :base_dn => 'OU=Person,DC=redmine,DC=org',
                                 :attr_login => 'uid',
                                 :attr_firstname => 'givenName',
                                 :attr_lastname => 'sn',
                                 :attr_mail => 'mail',
                                 :onthefly_register => true)


      end
      
      context "with a user that is found in LDAP" do
        should "create a new user" do
          assert_difference('User.count') do
            @handler.send(:find_user, @standard_email_address)
          end
        end
        
        should "set user for MailHandler" do
          user = @handler.send(:find_user, @standard_email_address)
          assert user
          assert_equal 'example1', user.login
        end
      end

      context "with a user that is not found in LDAP" do
        should 'return a nil user' do
          assert_equal nil, @handler.send(:find_user, @standard_email_address)
        end
      end
      
    end
  end
end

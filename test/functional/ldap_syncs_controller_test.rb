require File.dirname(__FILE__) + '/../test_helper'

class LdapSyncsControllerTest < ActionController::TestCase
  context "for non-admins" do
    should 'block access' do
      @request.session[:user_id] = User.generate_with_protected!

      get :show
      
      assert_response 403
    end
  end

  context "on GET to :show" do
    setup do
      @admin = User.generate_with_protected!
      @admin.admin = true
      @admin.save!
      @request.session[:user_id] = @admin
    end

    context "" do
      setup do
        get :show
      end
      
      should_respond_with :redirect
      should_redirect_to("authentication source list") { {:controller => 'auth_sources', :action => 'list' }}
      should_set_the_flash_to /complete/i
    end

    should "sync the LDAP and Redmine accounts" do
      # Isolate from the LDAP server
      ExtraLdap.expects(:add_new_users).with(:all).returns(true)
      ExtraLdap.expects(:lock_or_unlock_accounts).with(:all).returns(true)
      ExtraLdap.expects(:update_custom_user_data).with(:all).returns(true)

      get :show
    end
  end
end

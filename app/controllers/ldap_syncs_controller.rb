class LdapSyncsController < ApplicationController
  unloadable
  before_filter :require_admin

  def show
    ExtraLdap.add_new_users(:all)
    ExtraLdap.lock_or_unlock_accounts(:all)
    ExtraLdap.update_custom_user_data(:all)
    
    flash[:notice] = l(:label_sync_completed)
    redirect_to :controller => 'ldap_auth_sources', :action => 'index'
  end
end

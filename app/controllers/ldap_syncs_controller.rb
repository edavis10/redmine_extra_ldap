class LdapSyncsController < ApplicationController
  unloadable
  before_filter :require_admin

  def show
    ExtraLdap.add_new_users(:all)
    ExtraLdap.lock_or_unlock_accounts(:all)
    
    flash[:notice] = l(:label_sync_completed)
    redirect_to :controller => 'auth_sources', :action => 'list'
  end
end

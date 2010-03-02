class LdapSyncsController < ApplicationController
  unloadable
  before_filter :require_admin

  def show
    AuthSourceLdap.all.each do |ldap|
      ExtraLdap.add_new_users(ldap.name)
      ExtraLdap.lock_or_unlock_accounts(ldap.name)
    end
    
    flash[:notice] = l(:label_sync_completed)
    redirect_to :controller => 'auth_sources', :action => 'list'
  end
end

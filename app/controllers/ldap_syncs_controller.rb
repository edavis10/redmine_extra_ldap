class LdapSyncsController < ApplicationController
  unloadable
  before_filter :require_admin

  def show
    flash[:notice] = l(:label_sync_completed)
    redirect_to :controller => 'auth_sources', :action => 'list'
  end
end

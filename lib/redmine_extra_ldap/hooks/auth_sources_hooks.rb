module RedmineExtraLdap
  module Hook
    class AuthSourcesHooks < Redmine::Hook::ViewListener

      def view_auth_sources_list_contextual(context={})
        link_to(l(:label_sync_auth_sources), {:controller => 'ldap_syncs', :action => 'update'}, :class => 'icon icon-reload')
      end
    end
  end
end

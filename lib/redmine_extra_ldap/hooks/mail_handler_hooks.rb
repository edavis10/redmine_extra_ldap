module RedmineExtraLdap
  module Hook
    class MailHandlerHooks < Redmine::Hook::ViewListener

      # Try looking for (and creating) a user on the fly from LDAP
      #
      # Context:
      # * user
      # * sender_email
      # * email
      def model_mail_handler_find_user(context={})
        return '' if context[:user].present?
        return '' unless context[:sender_email].present?
        
        AuthSourceLdap.all(:conditions => {:onthefly_register => true}).each do |ldap|
          if ldap_user = ldap.find_user_by_email(context[:sender_email])
            context[:user] = User.create_from_ldap(ldap_user)
          end
        end
      end

    end
  end
end

class ExtraLdap
  def self.add_new_users(group=nil)
    if AuthSourceLdap.count == 0
      Rails.logger.info('ExtraLdap#add_new_users: no LDAP AuthSources found')
    else
      AuthSourceLdap.all.each do |ldap|
        ldap.add_new_users(:group => group)
      end
    end
  end
end

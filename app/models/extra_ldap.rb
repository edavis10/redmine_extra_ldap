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

  def self.lock_or_unlock_accounts
    AuthSourceLdap.all.each do |ldap|
      ldap.users.each do |user|
        if ldap.user_exists?(user)
          user.update_attributes(:status => User::STATUS_ACTIVE) unless user.active?
        else
          user.update_attributes(:status => User::STATUS_LOCKED) unless user.locked?
        end
      end
    end
  end

  # Add all of the existing users to a specific group unless they
  # already belong to a group.
  def self.add_existing_users_to_default_group(group_id)
    raise ArgumentError unless group_id.present?
    group = Group.find_by_id(group_id)
    group ||= Group.find_by_lastname(group_id)
    raise ArgumentError unless group.present?

    User.all(:include => :groups).each do |user|
      next if user.groups.count > 0
      user.groups << group
    end
  end
end

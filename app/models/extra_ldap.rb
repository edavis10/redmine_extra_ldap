class ExtraLdap
  def self.add_new_users(using_ldap_connection, group=nil)
    ldaps = ldap_connection(using_ldap_connection)

    ldaps.each {|ldap| ldap.add_new_users(:group => group) }
  end

  def self.lock_or_unlock_accounts(using_ldap_connection)
    ldaps = ldap_connection(using_ldap_connection)

    ldaps.each do |ldap|
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
  def self.add_existing_users_to_default_group(using_ldap_connection, group_id)
    raise ArgumentError unless group_id.present?
    group = Group.find_by_id(group_id)
    group ||= Group.find_by_lastname(group_id)
    raise ArgumentError unless group.present?
    ldaps = ldap_connection(using_ldap_connection)

    ldaps.each do |ldap|
      ldap.users.all(:include => :groups).each do |user|
        next if user.groups.count > 0
        user.groups << group
      end
    end
  end

  def self.update_custom_user_data(using_ldap_connection)
    ldaps = ldap_connection(using_ldap_connection)

    ldaps.each do |ldap|
      ldap.users.all.each do |user|
        attributes = ldap.get_custom_attributes_for_user(user.login)
        if attributes.present? && attributes[:custom_field_values].present?
          user.custom_field_values = attributes[:custom_field_values]
          user.save
        end
      end
    end
  end
  
  private

  def self.ldap_connection(name_or_id)
    if name_or_id.present? && name_or_id.to_s.downcase.to_sym == :all
      @ldap = AuthSourceLdap.all
    else
      @ldap = AuthSourceLdap.find_by_name(name_or_id)
      @ldap ||= AuthSourceLdap.find_by_id(name_or_id)
      raise ArgumentError, "LDAP connection named '#{name_or_id}' not found" unless @ldap.present?
      [@ldap]
    end
  end
end

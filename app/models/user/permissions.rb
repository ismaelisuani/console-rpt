module User::Permissions
  extend ActiveSupport::Concern

  def can?(permission)
    role.grants?(permission)
  end

  # Radio administrators see and operate every radio
  def all_radios?
    can?(:manage_radios)
  end
end

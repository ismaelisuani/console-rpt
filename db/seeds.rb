# The four base roles and a first administrator (change the password)
# Role names are data: created in the default language
roles = {
  administrator: Role::Permissions::ALL,
  supervisor: %w[view_dispatch listen transmit connect phone view_recordings manage_units],
  dispatcher: %w[view_dispatch listen transmit connect phone],
  listener: %w[view_dispatch listen]
}
roles.each do |key, permissions|
  Role.find_or_create_by!(name: I18n.t("roles.defaults.#{key}")) { |role| role.permissions = permissions }
end

User.find_or_create_by!(username: "admin") do |user|
  user.name = I18n.t("roles.defaults.administrator")
  user.password = ENV.fetch("ADMIN_PASSWORD", "change-me-now")
  user.role = Role.find_by!(name: I18n.t("roles.defaults.administrator"))
end

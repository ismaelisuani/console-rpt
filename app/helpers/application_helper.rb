module ApplicationHelper
  def initials(name)
    name.to_s.split.first(2).map { |word| word[0] }.join.upcase
  end

  ICONS = {
    mic: '<rect x="9" y="3" width="6" height="11" rx="3" fill="currentColor"/><path d="M5 11a7 7 0 0 0 14 0M12 18v3"/>',
    headphones: '<path d="M4 14v-2a8 8 0 0 1 16 0v2"/><rect x="3" y="14" width="4" height="6" rx="1" fill="currentColor"/><rect x="17" y="14" width="4" height="6" rx="1" fill="currentColor"/>',
    speaker: '<path d="M4 9h4l5-4v14l-5-4H4z" fill="currentColor"/><path d="M16 9a4 4 0 0 1 0 6M18.5 6.5a8 8 0 0 1 0 11"/>',
    speaker_muted: '<path d="M4 9h4l5-4v14l-5-4H4z" fill="currentColor"/><path d="M16 9l5 6M21 9l-5 6"/>',
    lock: '<rect x="5" y="11" width="14" height="9" rx="2" fill="currentColor"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/>'
  }.freeze

  def icon(name, size: "size-3.5")
    tag.svg(ICONS.fetch(name).html_safe, class: size, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor",
      "stroke-width": 2, "aria-hidden": true)
  end

  def decoder_label(decoder)
    t("decoders.#{decoder}", default: decoder.to_s)
  end

  def locale_options
    I18n.available_locales.map { |locale| [ t("locales.#{locale}"), locale ] }
  end

  NAV_ITEMS = [
    [ :dispatch, :view_dispatch, :dispatch_path, %w[dispatch] ],
    [ :radios, :manage_radios, :admin_radios_path, %w[admin/radios admin/radio_groups] ],
    [ :units, :manage_units, :units_path, %w[units] ],
    [ :servers, :manage_radios, :admin_servers_path, %w[admin/servers] ],
    [ :users, :manage_users, :admin_users_path, %w[admin/users] ],
    [ :roles, :manage_users, :admin_roles_path, %w[admin/roles] ]
  ].freeze

  def nav_items
    NAV_ITEMS.filter_map do |key, permission, path, controllers|
      next unless can?(permission)

      { label: t("nav.#{key}"), path: public_send(path), active: controllers.include?(controller_path) }
    end
  end
end

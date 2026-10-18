module ApplicationHelper
  # The RLink logo (or its "r" mark), in the version that fits the theme
  def brand_logo(css_class, mark: false)
    name = mark ? "rlink-mark" : "rlink-logo"
    image_tag("#{name}.png", alt: "RLink", class: "logo-light #{css_class}") +
      image_tag("#{name}-dark.png", alt: "RLink", class: "logo-dark #{css_class}")
  end

  def initials(name)
    name.to_s.split.first(2).map { |word| word[0] }.join.upcase
  end

  ICONS = {
    mic: '<rect x="9" y="3" width="6" height="11" rx="3" fill="currentColor"/><path d="M5 11a7 7 0 0 0 14 0M12 18v3"/>',
    headphones: '<path d="M4 14v-2a8 8 0 0 1 16 0v2"/><rect x="3" y="14" width="4" height="6" rx="1" fill="currentColor"/><rect x="17" y="14" width="4" height="6" rx="1" fill="currentColor"/>',
    speaker: '<path d="M4 9h4l5-4v14l-5-4H4z" fill="currentColor"/><path d="M16 9a4 4 0 0 1 0 6M18.5 6.5a8 8 0 0 1 0 11"/>',
    speaker_muted: '<path d="M4 9h4l5-4v14l-5-4H4z" fill="currentColor"/><path d="M16 9l5 6M21 9l-5 6"/>',
    lock: '<rect x="5" y="11" width="14" height="9" rx="2" fill="currentColor"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/>',
    menu: '<path d="M4 7h16M4 12h16M4 17h16"/>',
    sun: '<circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/>',
    moon: '<path d="M20 14.5A8 8 0 0 1 9.5 4 8 8 0 1 0 20 14.5z" fill="currentColor"/>',
    eye: '<path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/>',
    eye_off: '<path d="M2 12s3.5-7 10-7c2 0 3.7.7 5.1 1.6M22 12s-3.5 7-10 7c-2 0-3.7-.7-5.1-1.6"/><path d="M3 3l18 18"/>'
  }.freeze

  def icon(name, size: "size-3.5")
    tag.svg(ICONS.fetch(name).html_safe, class: size, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor",
      "stroke-width": 2, "aria-hidden": true)
  end

  # A password field with an eye button that shows what was typed
  def password_field_with_toggle(form, attribute, **options)
    tag.div(class: "relative", data: { controller: "password-visibility",
      password_visibility_show_label_value: t("password.show"), password_visibility_hide_label_value: t("password.hide") }) do
      form.password_field(attribute, **options, class: class_names(options[:class], "pr-10"),
        data: { password_visibility_target: "input" }) +
        tag.button(type: "button", class: "absolute inset-y-0 right-0 flex items-center px-3 text-muted hover:text-ink-strong",
          title: t("password.show"), aria: { label: t("password.show"), pressed: false },
          data: { action: "password-visibility#toggle", password_visibility_target: "button" }) do
          tag.span(icon(:eye, size: "size-4"), data: { password_visibility_target: "hidden" }) +
            tag.span(icon(:eye_off, size: "size-4"), hidden: true, data: { password_visibility_target: "shown" })
        end
    end
  end

  def decoder_label(decoder)
    t("decoders.#{decoder}", default: decoder.to_s)
  end

  # The servers in the top bar: how many are online, and each one's state as a tooltip
  def servers_status
    servers = Server.active.to_a
    online = servers.count(&:online?)
    {
      summary: t("servers.status.summary", online: online, count: servers.size),
      all_online: online == servers.size,
      details: servers.map { |server| "#{server.name}: #{t(server.online? ? "servers.status.online" : "servers.status.offline")}" }.join("\n")
    }
  end

  # The user's theme; before signing in, the last one picked in this browser
  def current_theme
    (Current.user&.theme || cookies[:theme]).presence_in(User::Preferences::THEMES) || "dark"
  end

  def theme_options
    User::Preferences::THEMES.map { |theme| [ t("theme.#{theme}"), theme ] }
  end

  def theme_toggle
    tag.button(type: "button", class: "btn btn-sm size-7 p-0", data: { controller: "theme", action: "theme#toggle",
      theme_url_value: (profile_path if authenticated?) },
      title: t("theme.switch"), aria: { label: t("theme.switch") }) do
      tag.span(icon(:sun), class: "hidden [[data-theme=dark]_&]:inline") + tag.span(icon(:moon), class: "hidden [[data-theme=light]_&]:inline")
    end
  end

  def locale_options
    I18n.available_locales.map { |locale| [ t("locales.#{locale}"), locale ] }
  end

  NAV_ITEMS = [
    [ :dispatch, :view_dispatch, :dispatch_path, %w[dispatch] ],
    [ :recordings, :view_recordings, :recordings_path, %w[recordings] ],
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

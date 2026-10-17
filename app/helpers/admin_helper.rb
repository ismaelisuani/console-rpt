module AdminHelper
  def server_status_badge(server)
    tag.span(t(server.online? ? "servers.status.online" : "servers.status.offline"),
      class: class_names("badge", server.online? ? "bg-rx-soft text-rx-ink" : "bg-tx-soft text-tx-ink"))
  end

  def recordings_sync_status(server)
    if server.recordings_sync_error.present?
      tag.span(t("admin.servers.index.sync_failed"), class: "badge bg-tx-soft text-tx-ink", title: server.recordings_sync_error)
    elsif server.recordings_synced_at
      safe_join([ t("admin.servers.index.synced"), local_time_tag(server.recordings_synced_at) ], " ")
    else
      tag.span("—", class: "text-faint")
    end
  end

  def permission_mark(role, permission)
    role.grants?(permission) ? tag.span("✓", class: "text-rx-ink") : tag.span("·", class: "text-faint")
  end

  def radio_group_access_badge(access)
    tag.span(access.radio_group.name,
      class: class_names("badge mr-1", access.level == "operate" ? "bg-accent-soft text-accent-ink" : "bg-warn-soft text-warn-ink"))
  end

  def radio_group_level_options(level)
    options_for_select([ [ t("radio_access.none"), "" ] ] + RadioGroupAccess::LEVELS.map { |l| [ t("radio_access.#{l}"), l ] }, level)
  end

  def inactive_row_class(record)
    "opacity-50" unless record.active?
  end
end

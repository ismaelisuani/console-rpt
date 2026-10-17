module DispatchHelper
  GRIDS = { "4" => [ 2, 2 ], "6" => [ 3, 2 ], "9" => [ 3, 3 ] }.freeze

  # What the current user can do on a radio tile
  def radio_tile_access(radio)
    @radio_tile_access ||= {}
    @radio_tile_access[radio.id] ||= {
      listen: Current.user.can_listen_to?(radio),
      transmit: Current.user.can_transmit_on?(radio),
      link: Current.user.can_connect?(radio),
      webrtc: radio.server.webrtc?
    }
  end

  def radio_tile_classes(radio)
    class_names("card flex min-w-0 flex-col gap-2 p-3 transition-colors",
      "has-[[data-receiving]]:border-rx has-[[data-receiving]]:ring-1 has-[[data-receiving]]:ring-rx",
      "has-[[data-transmitting]]:border-tx has-[[data-transmitting]]:ring-1 has-[[data-transmitting]]:ring-tx",
      "has-[[data-offline]]:opacity-55 data-[selected]:outline data-[selected]:outline-2 data-[selected]:outline-accent",
      "can-link": radio_tile_access(radio)[:link])
  end

  def radio_mode_badge(radio)
    access = radio_tile_access(radio)
    if access[:transmit]
      tag.span(class: "badge bg-accent-soft text-accent-ink") { icon(:mic) + t("dispatch.radio.mode.operate") }
    elsif access[:listen]
      tag.span(class: "badge bg-warn-soft text-warn-ink") { icon(:headphones) + t("dispatch.radio.mode.listen") }
    end
  end

  def radio_link_options(radio)
    Current.user.radios.active.where.not(id: radio.id).ordered.map { |other| [ "#{other.name} (#{other.node})", other.id ] }
  end

  # :offline, :receiving (it wins over the repeater's own transmission), :transmitting or :idle
  def radio_status(radio)
    if !radio.online? then :offline
    elsif radio.receiving? then :receiving
    elsif radio.transmitting? then :transmitting
    else :idle
    end
  end

  def radio_state_data(radio)
    { receiving: :receiving, transmitting: :transmitting, offline: :offline }.slice(radio_status(radio))
      .transform_values { "" }
  end

  STATUS_BAR = {
    offline: "bg-raised text-faint",
    receiving: "bg-rx-soft text-rx-ink",
    transmitting: "bg-tx-soft text-tx-ink",
    idle: "bg-raised text-muted"
  }.freeze

  def radio_status_bar(radio)
    status = radio_status(radio)
    tag.div(class: "flex h-7 items-center gap-2 truncate rounded px-2 text-xs font-bold uppercase tracking-wide #{STATUS_BAR[status]}") do
      safe_join(radio_status_bar_content(radio, status), " ")
    end
  end

  def radio_talking?(radio)
    radio.online? && radio.talking_unit_identified?
  end

  # "Móvil 12 · Juan Pérez" for a known unit, nil otherwise
  def unit_name(unit)
    [ unit.name, unit.person.presence ].compact.join(" · ") if unit
  end

  def unit_identifier_label(decoder, identifier)
    "#{identifier} · #{decoder_label(decoder)}"
  end

  # Who transmits: a console user, the radio that keyed it up through a link, or the node itself
  def transmitter_label(radio, node, user)
    return t("dispatch.radio.console_user", user: user.name) if user

    link_source_label(radio, node)
  end

  def link_source_label(radio, node)
    return t("dispatch.radio.local") if node.blank?

    Radio.find_by(server: radio.server, node: node)&.name || t("dispatch.radio.node", node: node)
  end

  def link_label(radio, link, linked)
    name = linked[link["node"]]&.name || link["node"]
    link["mode"] == "monitor" ? "#{name} (#{t("dispatch.radio.monitor").downcase})" : name
  end

  def link_badge_classes(link)
    link["mode"] == "monitor" ? "badge bg-warn-soft text-warn-ink" : "badge bg-accent-soft text-accent-ink"
  end

  def activity_description(event)
    case event.kind
    when "receive_start", "unit_identified" then reception_description(event)
    when "transmit_start"
      safe_join([ tag.span(t("dispatch.activity.tx"), class: "font-semibold text-tx-ink"), event.radio.name, "·",
        transmitter_label(event.radio, event.other_node, event.user) ], " ")
    when "linked", "unlinked"
      text = t("dispatch.activity.#{event.kind}", radio: event.radio.name, other: link_source_label(event.radio, event.other_node))
      event.user ? text + t("dispatch.activity.by", user: event.user.name) : text
    else
      t("dispatch.activity.#{event.kind}", radio: event.radio.name, server: event.server&.name)
    end
  end

  def dispatch_grid_style(layout)
    columns, rows = GRIDS.fetch(layout)
    "grid-template-columns: repeat(#{columns}, minmax(0, 1fr)); grid-auto-rows: calc((100% - #{rows - 1} * 0.75rem) / #{rows})"
  end

  # Texts for the Stimulus controllers
  def dispatch_strings_tag
    strings = %w[muted connected disconnected ptt_hold connect_first connecting call_failed call_ended microphone_denied]
      .to_h { |key| [ key.camelize(:lower), t("dispatch.radio.#{key}") ] }
    tag.script(json_escape(strings.to_json).html_safe, type: "application/json", id: "dispatch-strings")
  end

  def elapsed_tag(since)
    tag.span("", data: { controller: "elapsed", elapsed_since_value: since&.iso8601 }, class: "tabular-nums")
  end

  def local_time_tag(time, format: "time")
    tag.time(l(time, format: :short), datetime: time.iso8601, data: { controller: "local-time", local_time_format_value: format },
      class: "tabular-nums")
  end

  def level_meter(active)
    tag.span(class: "ml-auto flex items-end gap-0.5") do
      safe_join(6.times.map { |i| tag.i(class: class_names("w-1 rounded-sm bg-current", active ? "meter-bar" : "h-0.5"), style: ("animation-delay: #{i * 90}ms" if active)) })
    end
  end

  private
    def radio_status_bar_content(radio, status)
      case status
      when :offline
        [ t("dispatch.radio.server_down"), (safe_join([ "·", local_time_tag(radio.server.status_changed_at) ], " ") if radio.server.status_changed_at) ]
      when :receiving
        [ "◉", t("dispatch.radio.incoming_audio"), "·", elapsed_tag(radio.receiving_since), level_meter(true) ]
      when :transmitting
        [ "●", t("dispatch.radio.transmitting"), "·", elapsed_tag(radio.transmitting_since), level_meter(true) ]
      else
        [ "○", t("dispatch.radio.no_audio"),
          (safe_join([ "·", t("dispatch.radio.last_activity"), local_time_tag(radio.last_activity_at) ], " ") if radio.last_activity_at),
          level_meter(false) ]
      end.compact
    end

    def reception_description(event)
      unit = event.unit
      parts = [ tag.span(t("dispatch.activity.rx"), class: "font-semibold text-rx-ink"), event.radio.name ]
      if unit
        parts += [ "·", tag.b(unit_name(unit), class: "text-ink-strong"), "(#{event.unit_identifier})" ]
      elsif event.unit_identifier.present?
        parts += [ "·", tag.span("#{unit_identifier_label(event.decoder, event.unit_identifier)} #{t("dispatch.radio.unregistered")}", class: "text-warn-ink") ]
      end
      safe_join(parts, " ")
    end
end

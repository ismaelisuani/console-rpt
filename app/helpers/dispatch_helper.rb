module DispatchHelper
  # "Móvil 12 · Juan Pérez" for a known unit, nil otherwise
  def unit_name(unit)
    [ unit.name, unit.person.presence ].compact.join(" · ") if unit
  end

  def unit_identifier_label(decoder, identifier)
    "#{identifier} · #{decoder_label(decoder)}"
  end

  # The radio (or bare node) that keyed up a transmission through a link
  def link_source_label(radio, node)
    return t("dispatch.radio.local") if node.blank?

    Radio.find_by(server: radio.server, node: node)&.name || t("dispatch.radio.node", node: node)
  end

  # Who transmits: a console user, the radio that keyed it up through a link, or the node itself
  def transmitter_label(radio, node, user)
    return t("dispatch.radio.console_user", user: user.name) if user

    link_source_label(radio, node)
  end

  def elapsed_tag(since)
    tag.span("", data: { controller: "elapsed", elapsed_since_value: since&.iso8601 }, class: "tabular-nums")
  end

  def local_time_tag(time, format: "time")
    tag.time(l(time, format: :short), datetime: time.iso8601, data: { controller: "local-time", local_time_format_value: format },
      class: "tabular-nums")
  end

  def level_meter(active)
    tag.span(class: "ml-auto flex items-end gap-0.5", data: { meter: active }) do
      safe_join(6.times.map { |i| tag.i(class: class_names("w-1 rounded-sm bg-current", active ? "meter-bar" : "h-0.5"), style: ("animation-delay: #{i * 90}ms" if active)) })
    end
  end
end

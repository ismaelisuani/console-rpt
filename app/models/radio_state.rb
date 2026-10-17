# Applies the AMI RptEvent events of a node to its radio, logs the activity
# and pushes both to the dispatch screens
class RadioState
  # A unit ID that arrives this long before the receiver keys up still
  # identifies that reception (P25 sends it first)
  UNIT_LEAD = 3.seconds

  def self.server_changed(server)
    server.radios.each do |radio|
      radio.update!(receiving: false, transmitting: false, transmitted_by: nil) unless server.online?
      new(radio).tap do |state|
        state.send(:record, server.online? ? "server_online" : "server_offline", server: server)
        state.broadcast
      end
    end
    DispatchBroadcast.servers_status
  end

  def initialize(radio)
    @radio = radio
  end

  def apply(event)
    case event["Type"]
    when "RPTKEY" then key(event)
    when "UNITID" then unit(event)
    when "LINKS" then links(event)
    end
  end

  # "rpt nodes" output on connect: T<node> transceive, R<node> monitor,
  # C<node> still connecting
  def links_from_node_list(output)
    current = output.to_s.scan(/\b([TR])(\d+)\b/).map do |mode, node|
      { "node" => node, "mode" => mode == "R" ? "monitor" : "transceive" }
    end
    return if current == @radio.links

    @radio.update!(links: current)
    broadcast
  end

  def broadcast
    DispatchBroadcast.radio_state(@radio)
  end

  private
    def key(event)
      keyed = event["Value"] == "KEY"
      now = Time.current
      if event["Direction"] == "TX"
        return if @radio.transmitting? == keyed

        @radio.update!(transmitting: keyed, transmitted_by: (event["Who"].presence if keyed), transmitting_since: now, last_activity_at: now)
        record("transmit_start", other_node: event["Who"].presence) if keyed
      else
        return if @radio.receiving? == keyed

        @radio.update!(receiving: keyed, receiving_since: now, last_activity_at: now)
        if keyed
          recent_unit = @radio.unit_identified_at && @radio.unit_identified_at >= now - UNIT_LEAD
          record("receive_start", unit_identifier: (@radio.last_unit_identifier if recent_unit),
            decoder: (@radio.last_decoder if recent_unit))
        end
      end
      broadcast
    end

    def unit(event)
      now = Time.current
      @radio.update!(last_unit_identifier: event["Value"], last_decoder: event["Decoder"], unit_identified_at: now, last_activity_at: now)
      reception = current_reception
      if reception && reception.unit_identifier.blank?
        reception.update!(unit_identifier: event["Value"], decoder: event["Decoder"])
        DispatchBroadcast.activity_replaced(reception)
      else
        record("unit_identified", unit_identifier: event["Value"], decoder: event["Decoder"])
      end
      broadcast
    end

    def links(event)
      nodes = event["Value"].to_s.split(",").drop(1)
      monitor = event["Monitor"].to_s.split(",")
      current = nodes.map { |node| { "node" => node, "mode" => monitor.include?(node) ? "monitor" : "transceive" } }
      return if current == @radio.links

      before = @radio.links.map { |link| link["node"] }
      @radio.update!(links: current)
      (nodes - before).each { |node| record("linked", other_node: node, user_id: LinkRequest.take(@radio, node)) }
      (before - nodes).each { |node| record("unlinked", other_node: node, user_id: LinkRequest.take(@radio, node)) }
      broadcast
    end

    def current_reception
      return unless @radio.receiving?

      @radio.radio_events.where(kind: "receive_start").where(occurred_at: (@radio.receiving_since - 1.second)..).recent.first
    end

    def record(kind, **attributes)
      event = @radio.radio_events.create!(kind: kind, server: @radio.server, **attributes)
      DispatchBroadcast.activity(event)
      event
    end
end

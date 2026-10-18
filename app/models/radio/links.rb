# The node's links: kept from the AMI LINKS event (and "rpt nodes" when the
# listener connects), changed from the console with the stock DTMF functions
# (*1 disconnect, *2 monitor, *3 transceive)
module Radio::Links
  extend ActiveSupport::Concern

  FUNCTIONS = { "transceive" => "*3", "monitor" => "*2" }.freeze

  # [{ "node" => "2000", "mode" => "transceive" | "monitor" }], by node
  def linked_radios
    Radio.where(server: server, node: links.map { |link| link["node"] }).index_by(&:node)
  end

  def link_to!(other, mode:, by:)
    run_link_function(FUNCTIONS.fetch(mode, "*3"), other.node, by)
  end

  def unlink!(node, by:)
    run_link_function("*1", node, by)
  end

  # "rpt nodes" output: <node> or T<node> transceive, R<node> monitor,
  # C<node> still connecting (skipped)
  def links_from_node_list(output)
    current = output.to_s.scan(/\b([TRC]?)(\d+)\b/).filter_map do |mode, node|
      { "node" => node, "mode" => mode == "R" ? "monitor" : "transceive" } unless mode == "C"
    end
    return if current == links

    update!(links: current)
    broadcast_state
  end

  private
    def run_link_function(function, node, user)
      LinkRequest.remember(self, node, user)
      server.ami_command("rpt fun #{self.node} #{function}#{node}")
    end

    def links_reported(event)
      nodes = event["Value"].to_s.split(",").drop(1)
      monitor = event["Monitor"].to_s.split(",")
      current = nodes.map { |node| { "node" => node, "mode" => monitor.include?(node) ? "monitor" : "transceive" } }
      return if current == links

      before = links.map { |link| link["node"] }
      update!(links: current)
      (nodes - before).each { |node| log_event("linked", other_node: node, user_id: LinkRequest.take(self, node)) }
      (before - nodes).each { |node| log_event("unlinked", other_node: node, user_id: LinkRequest.take(self, node)) }
      broadcast_state
    end
end

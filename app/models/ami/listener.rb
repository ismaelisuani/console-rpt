module Ami
  # Keeps one AMI connection to a server open, turns its RptEvent events into
  # radio state and reconnects when the connection drops
  class Listener
    RETRY_DELAY = 5
    KEEPALIVE = 20

    def initialize(server_id, logger: Rails.logger)
      @server_id = server_id
      @logger = logger
      @stopping = false
    end

    def stop
      @stopping = true
    end

    def run
      until @stopping
        begin
          listen
        rescue Error, SystemCallError, IOError, SocketError, Timeout::Error => e
          @logger.warn("[ami] #{server&.name}: #{e.class}: #{e.message}")
        end
        set_online(false)
        sleep RETRY_DELAY unless @stopping
      end
    end

    private
      def server
        @server ||= app { Server.find_by(id: @server_id) }
      end

      def listen
        @server = nil
        return @stopping = true unless server&.active?

        connection = Connection.new(server, events: true)
        # Only the app_rpt events (needs "system" write; without it all call events arrive)
        connection.action("Filter", "Operation" => "Add", "Filter" => "Event: RptEvent")
        @logger.info("[ami] #{server.name}: connected")
        set_online(true)
        sync_links(connection)
        loop do
          break if @stopping

          message = connection.read_message(timeout: KEEPALIVE)
          if message.nil?
            connection.action("Ping") { |event| handle(event) }
          elsif message["Event"] == "RptEvent"
            handle(message)
          end
        end
      ensure
        connection&.close
      end

      def handle(event)
        return unless event["Event"] == "RptEvent"

        app do
          server.radios.find_by(node: event["Node"])&.apply_rpt_event(event)
        end
      end

      # Database work runs inside the Rails executor (connections, reloading)
      def app(&)
        Rails.application.executor.wrap(&)
      end

      # The LINKS event only comes on changes: the current links on connect
      def sync_links(connection)
        app { server.radios.active.to_a }.each do |radio|
          output = connection.command("rpt nodes #{radio.node}")
          app { radio.links_from_node_list(output) }
        rescue Error => e
          @logger.warn("[ami] #{server.name}: rpt nodes #{radio.node}: #{e.message}")
        end
      end

      def set_online(online)
        app { server&.reload&.mark_online!(online) }
      end
  end
end

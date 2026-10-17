module Ami
  # One listener thread per active server; picks up added or removed servers
  class Supervisor
    RESCAN = 15

    def initialize(logger: Rails.logger)
      @logger = logger
      @listeners = {}
    end

    def run
      trap_signals
      until @stopping
        Rails.application.executor.wrap { rescan }
        sleep RESCAN
      end
      @listeners.each_value { |entry| entry[:listener].stop }
    end

    private
      def rescan
        active = Server.active.pluck(:id)
        @listeners.each do |id, entry|
          next if active.include?(id) && entry[:thread].alive?

          entry[:listener].stop
          @listeners.delete(id)
        end
        (active - @listeners.keys).each do |id|
          listener = Listener.new(id, logger: @logger)
          thread = Thread.new { listener.run }
          @listeners[id] = { listener: listener, thread: thread }
        end
        Server.where.not(id: active).where(online: true).find_each do |server|
          server.update!(online: false, status_changed_at: Time.current)
          RadioState.server_changed(server)
        end
      end

      def trap_signals
        %w[INT TERM].each { |signal| Signal.trap(signal) { @stopping = true } }
      end
  end
end

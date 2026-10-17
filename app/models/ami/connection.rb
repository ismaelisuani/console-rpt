require "socket"

module Ami
  # A logged-in Asterisk Manager Interface connection. Messages are hashes of
  # header => value; "Output" headers (command output) are joined with "\n".
  class Connection
    attr_reader :server

    def initialize(server, events: false, timeout: 5)
      @server = server
      @timeout = timeout
      @action_id = 0
      @socket = Socket.tcp(server.host, server.ami_port, connect_timeout: timeout)
      banner = read_line
      raise Error, "not an AMI server: #{banner}" unless banner.start_with?("Asterisk Call Manager")

      response = action("Login", "Username" => server.ami_username, "Secret" => server.ami_password,
        "Events" => events ? "call" : "off")
      raise Error, response["Message"] || "login failed" unless response["Response"] == "Success"
    end

    # Sends an action and waits for its response (events that arrive in
    # between are handed to the block, if any)
    def action(name, headers = {})
      id = (@action_id += 1).to_s
      write({ "Action" => name, "ActionID" => id }.merge(headers))
      loop do
        message = read_message || raise(Timeout::Error, "AMI timeout waiting for #{name}")
        return message if message["ActionID"] == id && message.key?("Response")

        yield message if block_given? && message.key?("Event")
      end
    end

    def command(text)
      response = action("Command", "Command" => text)
      raise Error, response["Message"] || "command failed" unless response["Response"] == "Success"

      response["Output"].to_s
    end

    # Next message, or nil when nothing started arriving within the timeout
    def read_message(timeout: @timeout)
      return nil unless @buffer.to_s.include?("\n") || @socket.wait_readable(timeout)

      lines = []
      while (line = read_line).present?
        lines << line
      end
      parse(lines)
    end

    def close
      write({ "Action" => "Logoff" }) rescue nil
      @socket.close
    rescue IOError
      nil
    end

    private
      def write(headers)
        @socket.write(headers.map { |key, value| "#{key}: #{value.to_s.delete("\r\n")}\r\n" }.join + "\r\n")
      end

      def read_line(timeout: @timeout)
        @buffer ||= +""
        until (index = @buffer.index("\n"))
          raise Timeout::Error, "AMI timeout" if timeout && !@socket.wait_readable(timeout)

          chunk = @socket.read_nonblock(65_536, exception: false)
          next if chunk == :wait_readable
          raise EOFError, "AMI connection closed" if chunk.nil?

          @buffer << chunk.force_encoding(Encoding::UTF_8)
        end
        @buffer.slice!(0..index).chomp
      end

      def parse(lines)
        lines.each_with_object({}) do |line, message|
          key, value = line.split(":", 2)
          value = value.to_s.strip
          if key == "Output"
            message["Output"] = message.key?("Output") ? "#{message["Output"]}\n#{value}" : value
          else
            message[key] = value
          end
        end
      end
  end
end

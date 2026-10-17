module Ami
  # Short AMI sessions for the commands that users run from the web
  class Client
    def initialize(server)
      @server = server
    end

    def command(text)
      connection = Connection.new(@server)
      connection.command(text)
    ensure
      connection&.close
    end
  end
end

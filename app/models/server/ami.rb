# The server's Asterisk Manager Interface: credentials and short command sessions
module Server::Ami
  extend ActiveSupport::Concern

  CONNECTION_ERRORS = [ ::Ami::Error, SystemCallError, IOError, SocketError, Timeout::Error ].freeze

  included do
    encrypts :ami_password

    validates :ami_username, :ami_password, presence: true
    validates :ami_port, :ssh_port, numericality: { only_integer: true, in: 1..65_535 }
  end

  # An empty password field in a form keeps the stored one
  def ami_password=(value)
    super if value.present?
  end

  def ami_command(text)
    ::Ami::Client.new(self).command(text)
  end

  # The first line of "core show version"; raises one of CONNECTION_ERRORS
  def asterisk_version
    ami_command("core show version").to_s.lines.first.to_s.strip
  end
end

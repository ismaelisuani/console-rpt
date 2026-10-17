require "test_helper"

class Server::ConsoleCredentialsTest < ActiveSupport::TestCase
  test "servers get console credentials when created" do
    server = Server.create!(name: "New", host: "10.0.0.2", ami_username: "console", ami_password: "x")
    assert_equal 32, server.sip_password.size
    assert_equal 48, server.console_secret.size
  end

  test "empty password fields keep the stored passwords" do
    server = servers(:local)
    server.update!(ami_password: "", sip_password: "")
    assert_equal "secret", server.reload.ami_password
    assert_equal "sip-secret", server.sip_password
  end
end

require "test_helper"

class Server::UserExtensionsTest < ActiveSupport::TestCase
  test "one PJSIP endpoint and one extension per user with the phone" do
    users(:dispatcher).update!(sip_extension: "202", sip_password: "pw202")
    users(:listener).update!(sip_extension: "203", sip_password: "pw203")
    phone_users = User.all.select(&:phone_account?)
    server = servers(:local)

    pjsip = server.pjsip_users_config(phone_users)
    assert_includes pjsip, "[202]\ntype = endpoint"
    assert_includes pjsip, "password = pw202"
    assert_includes pjsip, %(callerid = "Dispatcher" <202>)
    assert_not_includes pjsip, "203", "the listener has no phone"

    dialplan = server.dialplan_users_config(phone_users)
    assert_includes dialplan, "[console-user-extensions]"
    assert_includes dialplan, "exten => 202,1,Dial(PJSIP/202,30)"
  end

  test "writes the files on the local server and reloads Asterisk" do
    dir = Dir.mktmpdir
    server = servers(:local)
    server.update!(asterisk_config_path: dir)
    commands = []
    server.define_singleton_method(:ami_command) { |text| commands << text }

    server.provision_user_extensions!

    assert File.exist?(File.join(dir, "pjsip_console_users.conf"))
    assert_includes File.read(File.join(dir, "extensions_console_users.conf")), "[console-user-extensions]"
    assert_equal [ "module reload res_pjsip.so", "dialplan reload" ], commands
  ensure
    FileUtils.rm_rf(dir)
  end
end

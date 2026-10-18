require "open3"

# The console users' extensions on the phone server: a PJSIP endpoint each
# (pjsip_console_users.conf) and their dialplan (extensions_console_users.conf),
# both included by the web-console configuration of asterisk-rpt. Written in
# place on the local server, over SSH on a remote one; then Asterisk reloads.
module Server::UserExtensions
  extend ActiveSupport::Concern

  class ProvisioningError < StandardError; end

  class_methods do
    def provision_user_extensions_later
      ProvisionUserExtensionsJob.perform_later
    end
  end

  def provision_user_extensions!
    users = User.includes(:role).order(:sip_extension).select(&:phone_account?)
    write_config_file("pjsip_console_users.conf", pjsip_users_config(users))
    write_config_file("extensions_console_users.conf", dialplan_users_config(users))
    ami_command("module reload res_pjsip.so")
    ami_command("dialplan reload")
  end

  def pjsip_users_config(users)
    header = "; Written by the web console (console-rpt): one endpoint per user with\n; the phone. Do not edit: it is rewritten when the users change.\n"
    header + users.map { |user| pjsip_user_sections(user) }.join
  end

  def dialplan_users_config(users)
    lines = users.flat_map do |user|
      [ "exten => #{user.sip_extension},1,Dial(PJSIP/#{user.sip_extension},30)",
        " same => n,Hangup()",
        "exten => #{user.sip_extension},hint,PJSIP/#{user.sip_extension}" ]
    end
    "; Written by the web console (console-rpt): its users' extensions.\n" \
      "; Do not edit: it is rewritten when the users change.\n[console-user-extensions]\n" + lines.map { "#{_1}\n" }.join
  end

  private
    def pjsip_user_sections(user)
      extension = user.sip_extension
      name = user.name.delete("\"\r\n;")
      <<~CONF

        [#{extension}]
        type = endpoint
        transport = transport-wss
        context = console-users
        disallow = all
        allow = ulaw
        webrtc = yes
        dtls_auto_generate_cert = yes
        dtmf_mode = rfc4733
        direct_media = no
        rtp_timeout = 30
        rtp_keepalive = 15
        callerid = "#{name}" <#{extension}>
        auth = #{extension}
        aors = #{extension}

        [#{extension}]
        type = auth
        auth_type = userpass
        username = #{extension}
        password = #{user.sip_password}

        [#{extension}]
        type = aor
        max_contacts = 5
        remove_existing = yes
      CONF
    end

    def write_config_file(name, content)
      path = File.join(asterisk_config_path, name)
      if local?
        File.write(path, content)
      else
        raise ProvisioningError, I18n.t("servers.recordings.no_ssh_user") if ssh_username.blank?

        remote = ssh_sudo? ? "sudo tee #{path} > /dev/null" : "cat > #{path}"
        output, status = Open3.capture2e("ssh", "-p", ssh_port.to_s, "-o", "BatchMode=yes", "-o", "StrictHostKeyChecking=accept-new",
          "-o", "ConnectTimeout=10", "#{ssh_username}@#{host}", remote, stdin_data: content)
        raise ProvisioningError, output.lines.last.to_s.strip unless status.success?
      end
    end
end

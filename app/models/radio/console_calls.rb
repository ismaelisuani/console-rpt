# The console's WebRTC call to the radio: the token fixes the node, the user
# and the level, operate (phone mode with PTT) or listen (monitor only)
module Radio::ConsoleCalls
  extend ActiveSupport::Concern

  def console_call_level(user)
    user.can_transmit_on?(self) ? "operate" : "listen"
  end

  def console_call(user)
    server.console_call(subject: node, level: console_call_level(user), user: user)
  end
end

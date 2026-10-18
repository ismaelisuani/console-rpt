# The console's phone: its calls go out through the server where the console
# runs (or the first one with WebRTC), to the dialplan's [console-phone-out]
module Server::ConsolePhone
  extend ActiveSupport::Concern

  NUMBER_FORMAT = /\A[0-9*#+]{1,32}\z/

  class_methods do
    def phone_server
      candidates = active.select(&:webrtc?)
      candidates.find(&:local?) || candidates.min_by(&:id)
    end
  end

  def phone_call(number, user)
    console_call(subject: number, level: "phone", user: user)
  end
end

# The console's phone server: where the users' extensions live and register
# (the server where the console runs, else the first one with WebRTC)
module Server::ConsolePhone
  extend ActiveSupport::Concern

  class_methods do
    def phone_server
      candidates = active.select(&:webrtc?)
      candidates.find(&:local?) || candidates.min_by(&:id)
    end
  end
end

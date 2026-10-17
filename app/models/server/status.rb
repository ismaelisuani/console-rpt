# Online or not, as the AMI listener sees it. Going offline clears the live
# state of the radios; both are logged and pushed to the dispatch screens.
module Server::Status
  extend ActiveSupport::Concern
  include LocalizedBroadcasts

  class_methods do
    def broadcast_status
      each_broadcast_locale do |locale|
        Turbo::StreamsChannel.broadcast_replace_to([ :servers_status, locale ], target: "servers_status", partial: "layouts/servers_status")
      end
    end
  end

  def mark_online!(online)
    return if online? == online

    update!(online: online, status_changed_at: Time.current)
    radios.each { |radio| radio.server_status_changed!(online) }
    self.class.broadcast_status
  end
end

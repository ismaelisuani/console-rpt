# The users' phone extensions on the phone server, after users or roles change
class ProvisionUserExtensionsJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: "user-extensions", duration: 5.minutes

  def perform
    Server.phone_server&.provision_user_extensions!
  end
end

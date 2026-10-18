require "test_helper"

class User::SipAccountTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def new_user(**attributes)
    User.create!({ name: "New", username: "new#{SecureRandom.hex(3)}", password: "secret", role: roles(:dispatcher) }.merge(attributes))
  end

  test "new users get the next free extension and a SIP password" do
    users(:admin).update!(sip_extension: "200")
    user = new_user
    assert_equal "201", user.sip_extension
    assert_equal 32, user.sip_password.size
  end

  test "an administrator can set the extension, which must be free" do
    assert_equal "250", new_user(sip_extension: "250").sip_extension
    assert_raises(ActiveRecord::RecordInvalid) { new_user(sip_extension: "250") }
    assert_raises(ActiveRecord::RecordInvalid) { new_user(sip_extension: "12a") }
  end

  test "only users with the phone permission get an endpoint" do
    assert new_user.phone_account?
    assert_not new_user(role: roles(:listener)).phone_account?
  end

  test "changes provision the extensions" do
    assert_enqueued_with(job: ProvisionUserExtensionsJob) { new_user }
  end
end

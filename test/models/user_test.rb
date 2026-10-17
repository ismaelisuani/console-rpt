require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "radio administrators operate every radio" do
    assert_equal :operate, users(:admin).access_to(radios(:other))
    assert users(:admin).can_transmit_on?(radios(:other))
  end

  test "access comes from the radio groups" do
    dispatcher = users(:dispatcher)
    assert_equal :operate, dispatcher.access_to(radios(:base))
    assert_nil dispatcher.access_to(radios(:other))
    assert_equal radios(:base, :mobile).sort, dispatcher.radios.sort
  end

  test "listen-only access or a role without transmit can't talk" do
    listener = users(:listener)
    assert listener.can_listen_to?(radios(:base))
    assert_not listener.can_transmit_on?(radios(:base))

    users(:dispatcher).radio_group_accesses.first.update!(level: "listen")
    assert_not users(:dispatcher).can_transmit_on?(radios(:base))
  end

  test "group levels from the user form" do
    user = users(:dispatcher)
    user.update!(group_levels: { radio_groups(:north).id.to_s => "listen" })
    assert_equal({ radio_groups(:north).id => "listen" }, user.reload.group_levels)

    user.update!(group_levels: { radio_groups(:north).id.to_s => "" })
    assert_empty user.reload.radio_group_accesses
  end
end

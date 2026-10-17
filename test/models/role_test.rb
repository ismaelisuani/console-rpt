require "test_helper"

class RoleTest < ActiveSupport::TestCase
  test "keeps only known permissions, in their order" do
    role = Role.new(name: "Test", permissions: [ "transmit", "fly", "", "listen" ])
    assert_equal %w[listen transmit], role.permissions
  end
end

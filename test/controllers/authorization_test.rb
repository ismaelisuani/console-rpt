require "test_helper"

class AuthorizationTest < ActionDispatch::IntegrationTest
  test "administration needs its permissions" do
    sign_in_as users(:dispatcher)
    [ admin_users_path, admin_roles_path, admin_servers_path, admin_radios_path, units_path ].each do |path|
      get path
      assert_redirected_to dispatch_path, path
    end
  end

  test "administrators get every page" do
    sign_in_as users(:admin)
    [ admin_users_path, admin_roles_path, admin_servers_path, admin_radios_path, admin_radio_groups_path, units_path,
      import_units_path, new_admin_user_path, new_admin_server_path, profile_path ].each do |path|
      get path
      assert_response :success, path
    end
  end

  test "linking needs the connect permission on that radio" do
    sign_in_as users(:listener)
    post link_radio_path(radios(:base)), params: { other_radio_id: radios(:mobile).id }
    assert_response :forbidden
  end

  test "users can't lock themselves out" do
    sign_in_as users(:admin)
    patch admin_role_path(roles(:administrator)), params: { role: { name: "Administrator", permissions: [ "listen" ] } }
    assert_response :unprocessable_entity
    assert roles(:administrator).reload.grants?(:manage_users)
  end
end

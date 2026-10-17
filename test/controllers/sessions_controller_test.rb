require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:dispatcher) }

  test "new" do
    get new_session_path
    assert_response :success
  end

  test "create with the username" do
    post session_path, params: { login: " Dispatcher ", password: "password" }

    assert_redirected_to root_path
    assert cookies[:session_id]
  end

  test "create with the email address" do
    post session_path, params: { login: @user.email_address, password: "password" }

    assert_redirected_to root_path
  end

  test "create with invalid credentials" do
    post session_path, params: { login: @user.username, password: "wrong" }

    assert_redirected_to new_session_path
    assert_nil cookies[:session_id]
  end

  test "inactive users can't sign in" do
    @user.update!(active: false)
    post session_path, params: { login: @user.username, password: "password" }

    assert_redirected_to new_session_path
  end

  test "destroy" do
    sign_in_as(@user)

    delete session_path

    assert_redirected_to new_session_path
    assert_empty cookies[:session_id]
  end
end

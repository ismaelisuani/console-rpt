require "test_helper"

class ProfilesTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:dispatcher) }

  test "the theme switch keeps the user's theme" do
    patch profile_path, params: { user: { theme: "light" } }, as: :json
    assert_response :no_content

    get dispatch_path
    assert_select "html[data-theme=light]"
  end

  test "only known themes" do
    patch profile_path, params: { user: { theme: "pink" } }, as: :json
    assert_response :unprocessable_entity
    assert_equal "dark", users(:dispatcher).reload.theme
  end
end

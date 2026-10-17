require "test_helper"

class DispatchControllerTest < ActionDispatch::IntegrationTest
  test "requires signing in" do
    get dispatch_path
    assert_redirected_to new_session_path
  end

  test "shows the radios the user can see, with their controls" do
    sign_in_as users(:dispatcher)
    get dispatch_path

    assert_response :success
    assert_select "article[data-controller=radio]", 2
    assert_select "button[data-radio-target=ptt]", 2
  end

  test "listen-only users get a locked PTT" do
    sign_in_as users(:listener)
    get dispatch_path

    assert_select "button[data-radio-target=ptt]", 0
    assert_select "article[data-controller=radio] button[disabled]", text: /PTT/
  end

  test "in the user's language" do
    users(:dispatcher).update!(locale: "pt-BR")
    sign_in_as users(:dispatcher)
    get dispatch_path

    assert_select "html[lang=pt-BR]"
    assert_select "h1", "Rádios"
  end
end

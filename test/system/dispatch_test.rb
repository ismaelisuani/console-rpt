require "application_system_test_case"

class DispatchTest < ApplicationSystemTestCase
  test "a dispatcher signs in and sees their radios, in their language" do
    sign_in "dispatcher"

    assert_selector "article[data-arrange-target=tile]", count: 2
    assert_text "Base"
    assert_selector "button", text: I18n.t("dispatch.show.group_ptt")
  end

  test "a click focuses a radio" do
    sign_in "dispatcher"
    find("article[data-name='Mobile'] [id^=state_]").click

    assert_equal "Mobile", page.evaluate_script("document.activeElement.closest('article').dataset.name")
  end

  test "listen-only radios have a locked PTT" do
    sign_in "listener"

    assert_selector "article[data-arrange-target=tile] button[disabled][title='#{I18n.t("dispatch.radio.no_permission")}']", count: 2
  end

  test "the light theme sticks" do
    sign_in "dispatcher"
    find("[data-controller=theme]").click

    assert_selector "html[data-theme=light]"
    visit dispatch_path
    assert_selector "html[data-theme=light]"
  end
end

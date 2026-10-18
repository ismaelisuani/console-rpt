require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # Chrome's password manager would warn that "password" leaked, and its
  # dialog steals the keyboard and the mouse from the page. The browser asks
  # for the default locale, whatever the machine's language
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1600, 1000 ] do |options|
    options.add_argument("--lang=#{I18n.default_locale}")
    options.add_preference("intl.accept_languages", I18n.default_locale.to_s)
    options.add_argument("--disable-features=PasswordLeakDetection,PasswordCheck")
    options.add_preference("credentials_enable_service", false)
    options.add_preference("profile.password_manager_enabled", false)
    options.add_preference("profile.password_manager_leak_detection", false)
  end

  # Waits until signed in (the top bar shows), unless the password is wrong
  def sign_in(username, password: "password")
    visit new_session_path
    fill_in "login", with: username
    fill_in "password", with: password
    click_on I18n.t("sessions.sign_in")
    assert_selector "header button", text: I18n.t("sessions.sign_out") if password == "password"
  end
end

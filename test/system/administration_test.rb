require "application_system_test_case"

class AdministrationTest < ApplicationSystemTestCase
  test "an administrator adds a unit" do
    sign_in "admin"
    visit units_path
    click_on I18n.t("actions.new")

    fill_in Unit.human_attribute_name(:identifier), with: "4410"
    select "MDC1200", from: Unit.human_attribute_name(:decoder)
    fill_in Unit.human_attribute_name(:name), with: "Repeater"
    click_on I18n.t("actions.save")

    assert_text "Repeater"
    assert Unit.lookup("MDC1200", "4410")
  end

  test "the address book and a favorite" do
    sign_in "dispatcher"
    visit contacts_path
    click_on I18n.t("actions.new")
    fill_in Contact.human_attribute_name(:name), with: "Fire station"
    fill_in Contact.human_attribute_name(:number), with: "100"
    click_on I18n.t("actions.save")

    click_on "☆"
    assert_selector "button", text: "★"
  end

  test "a wrong password" do
    sign_in "dispatcher", password: "wrong"
    assert_text I18n.t("sessions.invalid")
  end
end

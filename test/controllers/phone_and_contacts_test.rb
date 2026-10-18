require "test_helper"

class PhoneAndContactsTest < ActionDispatch::IntegrationTest
  test "the browser gets the user's own extension" do
    users(:dispatcher).update!(sip_extension: "202", sip_password: "pw202")
    sign_in_as users(:dispatcher)
    get phone_account_path, as: :json

    assert_response :success
    assert_equal({ "ws" => "wss://radio.example.com:8089/ws", "host" => "radio.example.com", "extension" => "202",
      "password" => "pw202", "name" => "Dispatcher" }, response.parsed_body)
  end

  test "no phone without the permission" do
    sign_in_as users(:listener)
    get phone_account_path, as: :json
    assert_response :forbidden
  end

  test "contacts and favorites" do
    sign_in_as users(:dispatcher)
    post contacts_path, params: { contact: { name: "Central Bomberos", number: "0261 425-3300" } }
    contact = Contact.find_by!(name: "Central Bomberos")
    assert_equal "02614253300", contact.number

    post contact_favorite_path(contact)
    assert_equal [ contact ], users(:dispatcher).favorite_contacts.to_a

    get dispatch_path
    assert_select "aside [data-number='02614253300']", 1

    delete contact_favorite_path(contact)
    assert_empty users(:dispatcher).reload.favorite_contacts
  end
end

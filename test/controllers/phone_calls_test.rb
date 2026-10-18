require "test_helper"

class PhoneCallsTest < ActionDispatch::IntegrationTest
  test "a phone call through the server with WebRTC, signed for the number" do
    sign_in_as users(:dispatcher)
    post phone_call_path, params: { number: "0261 425-3300" }, as: :json

    assert_response :success
    call = response.parsed_body
    assert_equal "sip:02614253300@radio.example.com", call["uri"]
    assert_equal "phone", call["level"]
    expires, level, user_id, signature = call["token"].split(":")
    assert_equal Digest::SHA1.hexdigest("console-secret:02614253300:#{expires}:phone:#{user_id}"), signature
    assert_equal [ "phone", users(:dispatcher).id.to_s ], [ level, user_id ]
  end

  test "only numbers" do
    sign_in_as users(:dispatcher)
    post phone_call_path, params: { number: "100@evil" }, as: :json
    assert_response :unprocessable_entity
  end

  test "needs the phone permission" do
    sign_in_as users(:listener)
    post phone_call_path, params: { number: "600" }, as: :json
    assert_response :forbidden
  end

  test "no server with WebRTC" do
    servers(:local).update!(webrtc_url: nil)
    sign_in_as users(:dispatcher)
    post phone_call_path, params: { number: "600" }, as: :json
    assert_response :service_unavailable
  end
end

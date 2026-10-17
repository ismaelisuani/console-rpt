require "test_helper"

class RadioAudioTest < ActionDispatch::IntegrationTest
  test "a call with the user's level" do
    sign_in_as users(:listener)
    post radio_call_path(radios(:base)), as: :json

    assert_response :success
    assert_equal "listen", response.parsed_body["level"]
  end

  test "no call to radios outside the user's groups" do
    sign_in_as users(:dispatcher)
    post radio_call_path(radios(:other)), as: :json
    assert_response :not_found
  end

  test "no call without WebRTC on the server" do
    servers(:local).update!(webrtc_url: nil)
    sign_in_as users(:dispatcher)
    post radio_call_path(radios(:base)), as: :json
    assert_response :unprocessable_entity
  end

  test "PTT names the next console transmission" do
    sign_in_as users(:dispatcher)
    post radio_ptt_path(radios(:base))
    assert_response :no_content

    radios(:base).reload.apply_rpt_event("Type" => "RPTKEY", "Who" => "", "Value" => "KEY", "Direction" => "TX")
    assert_equal users(:dispatcher), radios(:base).reload.transmitted_by_user
    assert_equal users(:dispatcher), radios(:base).radio_events.find_by!(kind: "transmit_start").user
  end

  test "listeners can't press PTT" do
    sign_in_as users(:listener)
    post radio_ptt_path(radios(:base))
    assert_response :forbidden
  end
end

require "test_helper"

class RecordingsTest < ActionDispatch::IntegrationTest
  setup do
    servers(:local).update!(archive_path: file_fixture("archive").to_s)
    servers(:local).sync_recordings!
    roles(:dispatcher).update!(permissions: roles(:dispatcher).permissions + [ "view_recordings" ])
  end

  test "the recordings page" do
    sign_in_as users(:dispatcher)
    get recordings_path(direction: "rx")

    assert_response :success
    assert_select "tbody tr", 1
    assert_select "audio[src]", 1
  end

  test "the audio, playable" do
    sign_in_as users(:dispatcher)
    get recording_audio_path(Recording.find_by!(direction: "rx"))

    assert_response :success
    assert_equal "audio/wav", response.media_type
  end

  test "needs the recordings permission" do
    sign_in_as users(:listener)
    get recordings_path
    assert_redirected_to dispatch_path
  end
end

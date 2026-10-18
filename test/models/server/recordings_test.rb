require "test_helper"
require "turbo/broadcastable/test_helper"

class Server::RecordingsTest < ActiveSupport::TestCase
  include Turbo::Broadcastable::TestHelper
  setup do
    @server = servers(:local)
    @server.update!(archive_path: file_fixture("archive").to_s)
  end

  test "imports the local archive once" do
    assert_difference -> { @server.recordings.count }, 2 do
      @server.sync_recordings!
    end
    assert_no_difference -> { Recording.count } do
      @server.update_columns(recordings_synced_at: nil)
      @server.sync_recordings!
    end
    assert @server.reload.recordings_synced_at
  end

  test "open recordings pages refresh when new recordings come in" do
    assert_turbo_stream_broadcasts(:recordings, count: 1) { @server.sync_recordings! }

    # nothing new the second time
    ActionCable.server.pubsub.clear
    @server.update_columns(recordings_synced_at: nil)
    assert_no_turbo_stream_broadcasts(:recordings) { @server.sync_recordings! }
  end

  test "what each recording keeps" do
    @server.sync_recordings!
    rx = @server.recordings.find_by!(link_id: "0100120261017103403397")
    assert_equal radios(:base), rx.radio
    assert_equal "rx", rx.direction
    assert_equal [ "7301", "Mototrbo", "2000" ], [ rx.unit_identifier, rx.decoder, rx.remote_node ]
    assert_equal BigDecimal("3.58"), rx.duration
    assert_equal Time.find_zone("America/Argentina/Buenos_Aires").parse("2026-10-17 10:34:03.397"), rx.started_at
    assert_equal "1999/0100120261017103403397.WAV", rx.audio_path

    tx = @server.recordings.find_by!(link_id: "0100120261017103406444")
    assert_equal [ "tx", "2000", nil ], [ tx.direction, tx.other_node, tx.unit_identifier ]
  end

  test "remote servers need an SSH user" do
    @server.update!(local: false, ssh_username: nil)
    @server.sync_recordings
    assert_match "SSH", @server.reload.recordings_sync_error
  end

  test "the browser gets PCM audio" do
    @server.sync_recordings!
    path = @server.recordings.find_by!(direction: "rx").playable_audio
    assert_equal "RIFF", File.binread(path, 4)
    assert_raises(Recording::Audio::Missing) { @server.recordings.find_by!(direction: "tx").playable_audio }
  end
end

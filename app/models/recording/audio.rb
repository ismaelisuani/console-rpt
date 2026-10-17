# The archive's audio is GSM 6.10 in WAV, which browsers don't play: it is
# converted once to 16-bit PCM WAV (sox) and kept next to the app's storage
module Recording::Audio
  extend ActiveSupport::Concern

  class Missing < StandardError; end

  def archive_audio
    server.archive_root.join(audio_path)
  end

  def playable_audio
    target = Rails.configuration.x.playable_audio_dir.join(server_id.to_s, "#{link_id}.wav")
    return target if target.exist?
    raise Missing, audio_path unless archive_audio.exist?

    target.dirname.mkpath
    partial = target.sub_ext(".partial.wav")
    converted = system("sox", archive_audio.to_s, "-e", "signed-integer", "-b", "16", partial.to_s, err: File::NULL)
    raise Missing, audio_path unless converted

    File.rename(partial, target)
    target
  end

  def download_filename
    "#{radio&.name || node} #{started_at.strftime("%Y-%m-%d %H%M%S")}.wav"
  end
end

# The audio of a recording, playable in the browser (or as a download)
class Recordings::AudiosController < ApplicationController
  require_permission :view_recordings

  def show
    recording = Recording.visible_to(Current.user).find(params.expect(:recording_id))
    send_file recording.playable_audio, type: "audio/wav", filename: recording.download_filename,
      disposition: params[:download] ? "attachment" : "inline"
  rescue Recording::Audio::Missing
    head :not_found
  end
end

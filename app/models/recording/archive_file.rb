# The .txt that app_rpt writes next to each recording of the air archive
# (rlink_airlog.c): key=value lines, times in the server's local time.
module Recording::ArchiveFile
  extend ActiveSupport::Concern

  LINK_ID_FORMAT = /\A[0-9A-Za-z_-]+\z/

  class_methods do
    # Recording attributes from the .txt of a node directory, nil if it isn't one
    def attributes_from_archive(text, server:, node_dir:)
      fields = text.each_line.filter_map do |line|
        key, value = line.chomp.split("=", 2)
        [ key, value.to_s.strip ] if value
      end.to_h
      link_id = fields["LinkId"].to_s
      # Also the file names: never anything that could leave the archive
      return unless link_id.match?(LINK_ID_FORMAT) && node_dir.match?(LINK_ID_FORMAT)

      tx = fields["EntraSale"] == "S"
      dato8 = fields["Dato8"].presence
      wav = File.basename(fields["WavPathname"].presence || "#{link_id}.WAV")
      wav = "#{link_id}.WAV" unless wav.match?(/\A[0-9A-Za-z_.-]+\z/) && !wav.start_with?(".")
      {
        server_id: server.id,
        node: fields["Canal"].presence || node_dir,
        link_id: link_id,
        direction: tx ? "tx" : "rx",
        started_at: archive_time(fields["Fecha"], fields["Hora"], link_id, server),
        duration: (fields["Milisegundos"].presence || fields["Segundos"]).to_d,
        unit_identifier: (dato8 unless tx),
        other_node: (dato8 if tx),
        decoder: fields["Dato10"].presence,
        remote_node: fields["Dato9"].presence,
        audio_path: File.join(node_dir, wav)
      }
    rescue ArgumentError
      nil
    end

    private
      # Fecha + Hora, plus the milliseconds at the end of the LinkId
      def archive_time(date, time, link_id, server)
        zone = ActiveSupport::TimeZone[server.time_zone] || Time.zone
        zone.strptime("#{date}#{time}", "%Y%m%d%H%M%S") + (link_id.last(3).to_i / 1000.0)
      end
  end
end

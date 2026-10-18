# The recordings a user may hear, and the filters of the recordings page
module Recording::Filtering
  extend ActiveSupport::Concern

  included do
    # Recordings of radios not registered in the console: radio administrators only
    scope :visible_to, ->(user) { user.all_radios? ? all : where(radio_id: user.radios.select(:id)) }
  end

  class_methods do
    def filtered(filters)
      scope = all
      scope = scope.where(radio_id: filters[:radio_id]) if filters[:radio_id].present?
      scope = scope.where(direction: filters[:direction]) if Recording::DIRECTIONS.include?(filters[:direction])
      if (from = parse_date(filters[:from]))
        scope = scope.where(started_at: from.beginning_of_day..)
      end
      if (to = parse_date(filters[:to]))
        scope = scope.where(started_at: ..to.end_of_day)
      end
      scope = scope.matching_unit(filters[:unit]) if filters[:unit].present?
      scope
    end

    # The ID itself, the name or person of the unit it belongs to, or the
    # console user who talked
    def matching_unit(text)
      pattern = "%#{sanitize_sql_like(text.strip)}%"
      where(unit_identifier: text.strip).or(where(<<~SQL, pattern: pattern))
        EXISTS (SELECT 1 FROM units WHERE units.decoder = recordings.decoder
          AND units.identifier = recordings.unit_identifier
          AND (units.name ILIKE :pattern OR units.person ILIKE :pattern))
        OR EXISTS (SELECT 1 FROM users WHERE users.id = recordings.user_id
          AND (users.name ILIKE :pattern OR users.username ILIKE :pattern))
      SQL
    end

    private
      def parse_date(value)
        Date.iso8601(value.to_s) if value.present?
      rescue Date::Error
        nil
      end
  end
end

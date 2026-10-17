require "csv"

# Loads units from a CSV file (identifier, decoder, name, person, fleet,
# active), creating or updating them by decoder + identifier
class Unit::Import
  HEADERS = %w[identifier decoder name person fleet active].freeze
  Result = Struct.new(:created, :updated, :errors)

  def initialize(file)
    @file = file
  end

  def run
    result = Result.new(0, 0, [])
    rows = CSV.parse(read, headers: true, header_converters: ->(h) { h.to_s.strip.downcase }, col_sep: separator)
    Unit.transaction do
      rows.each.with_index(2) { |row, line| import_row(row, line, result) }
      raise ActiveRecord::Rollback if result.errors.any?
    end
    result
  rescue CSV::MalformedCSVError => e
    Result.new(0, 0, [ e.message ])
  end

  private
    def read
      @read ||= @file.read.force_encoding("UTF-8").delete_prefix("﻿")
    end

    # Spreadsheets in Spanish or Portuguese often export with ";"
    def separator
      first_line = read.lines.first.to_s
      first_line.count(";") > first_line.count(",") ? ";" : ","
    end

    def import_row(row, line, result)
      decoder = Unit::DECODERS.find { |name| name.casecmp?(row["decoder"].to_s.strip) } || row["decoder"]
      unit = Unit.find_or_initialize_by(decoder: decoder, identifier: row["identifier"].to_s.strip)
      unit.assign_attributes(name: row["name"], person: row["person"], fleet: row["fleet"],
        active: row["active"].blank? || ActiveModel::Type::Boolean.new.cast(row["active"].strip))
      new_record = unit.new_record?
      if unit.save
        new_record ? result.created += 1 : result.updated += 1
      else
        result.errors << I18n.t("units.import.row_error", line: line, errors: unit.errors.full_messages.to_sentence)
      end
    end
end

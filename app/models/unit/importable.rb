require "csv"

# Loads units from a CSV file (identifier, decoder, name, person, fleet,
# active), creating or updating them by decoder + identifier. Nothing is
# saved if a line has errors.
module Unit::Importable
  extend ActiveSupport::Concern

  IMPORT_HEADERS = %w[identifier decoder name person fleet active].freeze
  ImportResult = Struct.new(:created, :updated, :errors)

  class_methods do
    def import(file)
      text = file.read.force_encoding("UTF-8").delete_prefix("﻿")
      result = ImportResult.new(0, 0, [])
      rows = CSV.parse(text, headers: true, header_converters: ->(h) { h.to_s.strip.downcase }, col_sep: csv_separator(text))
      transaction do
        rows.each.with_index(2) { |row, line| import_row(row, line, result) }
        raise ActiveRecord::Rollback if result.errors.any?
      end
      result
    rescue CSV::MalformedCSVError => e
      ImportResult.new(0, 0, [ e.message ])
    end

    private
      # Spreadsheets in Spanish or Portuguese often export with ";"
      def csv_separator(text)
        first_line = text.lines.first.to_s
        first_line.count(";") > first_line.count(",") ? ";" : ","
      end

      def import_row(row, line, result)
        unit = find_or_initialize_by(decoder: decoder_named(row["decoder"]), identifier: row["identifier"].to_s.strip)
        unit.assign_attributes(name: row["name"], person: row["person"], fleet: row["fleet"],
          active: row["active"].blank? || ActiveModel::Type::Boolean.new.cast(row["active"].strip))
        new_record = unit.new_record?
        if unit.save
          new_record ? result.created += 1 : result.updated += 1
        else
          result.errors << I18n.t("units.imports.row_error", line: line, errors: unit.errors.full_messages.to_sentence)
        end
      end
  end
end

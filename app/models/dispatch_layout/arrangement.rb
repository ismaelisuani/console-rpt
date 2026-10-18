# Where each radio tile goes on the board, a column and a row:
# [{ "radio_id" => 1, "x" => 1, "y" => 2 }, ...]
# Tiles without a place fill the free cells
module DispatchLayout::Arrangement
  extend ActiveSupport::Concern

  MAX_COLUMN = 3
  MAX_ROW = 50

  included do
    normalizes :tiles, with: ->(tiles) {
      Array(tiles).filter_map do |tile|
        tile = tile.to_h.stringify_keys
        next if tile["radio_id"].to_i <= 0

        position = { "x" => tile["x"].to_i.clamp(1, MAX_COLUMN), "y" => tile["y"].to_i.clamp(1, MAX_ROW) } if tile["x"].present? && tile["y"].present?
        { "radio_id" => tile["radio_id"].to_i }.merge(position.to_h)
      end.uniq { |tile| tile["radio_id"] }
    }
  end

  # The radios by row and column (the order on small screens); radios not in
  # the layout yet go last
  def arrange(radios)
    order = tiles.each_with_index.to_h { |tile, index| [ tile["radio_id"], [ tile["y"] || MAX_ROW + 1, tile["x"] || 0, index ] ] }
    radios.each_with_index.sort_by { |radio, index| order.fetch(radio.id, [ MAX_ROW + 2, 0, tiles.size + index ]) }.map(&:first)
  end

  # [column, row], or nil when the tile goes in the next free cell
  def tile_position(radio)
    tile = tiles.find { |t| t["radio_id"] == radio.id }
    [ tile["x"], tile["y"] ] if tile&.key?("x")
  end
end

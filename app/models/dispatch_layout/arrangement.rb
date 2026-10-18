# Where each radio tile goes and its size, in grid cells:
# [{ "radio_id" => 1, "x" => 1, "y" => 2, "w" => 2, "h" => 1 }, ...]
# x (column) and y (row) are optional: tiles without them fill the free cells
module DispatchLayout::Arrangement
  extend ActiveSupport::Concern

  MAX_WIDTH = 3
  MAX_HEIGHT = 3
  MAX_ROW = 50

  included do
    normalizes :tiles, with: ->(tiles) {
      Array(tiles).filter_map do |tile|
        tile = tile.to_h.stringify_keys
        next if tile["radio_id"].to_i <= 0

        position = { "x" => tile["x"].to_i.clamp(1, MAX_WIDTH), "y" => tile["y"].to_i.clamp(1, MAX_ROW) } if tile["x"].present? && tile["y"].present?
        { "radio_id" => tile["radio_id"].to_i, "w" => tile["w"].to_i.clamp(1, MAX_WIDTH), "h" => tile["h"].to_i.clamp(1, MAX_HEIGHT) }
          .merge(position.to_h)
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

  def tile_size(radio)
    tile = tiles.find { |t| t["radio_id"] == radio.id }
    tile ? [ tile["w"], tile["h"] ] : [ 1, 1 ]
  end
end

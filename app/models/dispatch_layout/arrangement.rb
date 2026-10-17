# The order and size of the radio tiles: [{ "radio_id" => 1, "w" => 2, "h" => 1 }, ...]
# in screen order; w and h are grid cells
module DispatchLayout::Arrangement
  extend ActiveSupport::Concern

  MAX_WIDTH = 3
  MAX_HEIGHT = 3

  included do
    normalizes :tiles, with: ->(tiles) {
      Array(tiles).filter_map do |tile|
        tile = tile.to_h.stringify_keys
        next if tile["radio_id"].to_i <= 0

        { "radio_id" => tile["radio_id"].to_i, "w" => tile["w"].to_i.clamp(1, MAX_WIDTH), "h" => tile["h"].to_i.clamp(1, MAX_HEIGHT) }
      end.uniq { |tile| tile["radio_id"] }
    }
  end

  # The radios in the saved order; radios not in the layout yet go last
  def arrange(radios)
    order = tiles.each_with_index.to_h { |tile, index| [ tile["radio_id"], index ] }
    radios.each_with_index.sort_by { |radio, index| [ order.fetch(radio.id, tiles.size + index) ] }.map(&:first)
  end

  def tile_size(radio)
    tile = tiles.find { |t| t["radio_id"] == radio.id }
    tile ? [ tile["w"], tile["h"] ] : [ 1, 1 ]
  end
end

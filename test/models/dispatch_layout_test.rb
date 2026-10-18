require "test_helper"

class DispatchLayoutTest < ActiveSupport::TestCase
  test "places on the board, by row and column, within the board" do
    layout = users(:dispatcher).dispatch_layout_for(radio_groups(:north))
    layout.update!(tiles: [ { radio_id: radios(:base).id, x: 2, y: 3 }, { radio_id: radios(:mobile).id, x: 9, y: "1" }, { radio_id: 0 } ])

    assert_equal [ 3, 1 ], layout.tile_position(radios(:mobile))
    assert_equal [ radios(:mobile), radios(:base) ], layout.arrange([ radios(:base), radios(:mobile) ])
  end

  test "radios without a place go last, in the next free cells" do
    layout = DispatchLayout.new(tiles: [ { radio_id: radios(:mobile).id, x: 1, y: 1 } ])
    assert_equal [ radios(:mobile), radios(:base), radios(:other) ], layout.arrange([ radios(:base), radios(:mobile), radios(:other) ])
    assert_nil layout.tile_position(radios(:other))
  end
end

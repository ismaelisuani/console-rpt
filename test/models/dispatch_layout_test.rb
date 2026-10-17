require "test_helper"

class DispatchLayoutTest < ActiveSupport::TestCase
  test "keeps the saved order and sizes, within limits" do
    layout = users(:dispatcher).dispatch_layout_for(radio_groups(:north))
    layout.update!(tiles: [ { radio_id: radios(:mobile).id, w: 9, h: "2" }, { "radio_id" => radios(:base).id }, { radio_id: 0 } ])

    assert_equal [ radios(:mobile), radios(:base) ], layout.arrange([ radios(:base), radios(:mobile) ])
    assert_equal [ 3, 2 ], layout.tile_size(radios(:mobile))
    assert_equal [ 1, 1 ], layout.tile_size(radios(:base))
  end

  test "radios that aren't in the layout go last" do
    layout = DispatchLayout.new(tiles: [ { radio_id: radios(:mobile).id } ])
    assert_equal [ radios(:mobile), radios(:base), radios(:other) ], layout.arrange([ radios(:base), radios(:mobile), radios(:other) ])
  end
end

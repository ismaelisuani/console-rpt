require "test_helper"

class DispatchLayoutsTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:dispatcher) }

  test "saves the arrangement of a group, and the screen uses it" do
    patch dispatch_layout_path(group_id: radio_groups(:north).id),
      params: { tiles: [ { radio_id: radios(:mobile).id, x: 1, y: 1 }, { radio_id: radios(:base).id, x: 2, y: 1 } ] }, as: :json
    assert_response :no_content

    get dispatch_path(group_id: radio_groups(:north).id)
    assert_select "article[data-arrange-target=tile]" do |tiles|
      assert_equal [ radios(:mobile).id.to_s, radios(:base).id.to_s ], tiles.map { |t| t["data-radio-id"] }
      assert_match "--x: 1; --y: 1", tiles.first["style"]
    end
  end
end

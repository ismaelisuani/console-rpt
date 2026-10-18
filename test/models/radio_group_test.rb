require "test_helper"

class RadioGroupTest < ActiveSupport::TestCase
  test "deleting a group also deletes its screen arrangements and accesses" do
    users(:dispatcher).dispatch_layout_for(radio_groups(:north)).update!(tiles: [ { radio_id: radios(:base).id } ])

    assert radio_groups(:north).destroy
    assert_not DispatchLayout.exists?(radio_group_id: radio_groups(:north).id)
    assert_not RadioGroupAccess.exists?(radio_group_id: radio_groups(:north).id)
  end
end

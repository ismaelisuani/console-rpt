require "test_helper"

class Recording::FilteringTest < ActiveSupport::TestCase
  setup do
    servers(:local).update!(archive_path: file_fixture("archive").to_s)
    servers(:local).sync_recordings!
  end

  test "users hear the recordings of their radios" do
    assert_equal 2, Recording.visible_to(users(:dispatcher)).count
    radio_groups(:north).radios.delete(radios(:base))
    assert_equal 0, Recording.visible_to(users(:dispatcher).reload).count
    assert_equal 2, Recording.visible_to(users(:admin)).count
  end

  test "filters" do
    assert_equal [ "rx" ], Recording.filtered(direction: "rx").pluck(:direction)
    assert_equal 1, Recording.filtered(unit: "john").count
    assert_equal 1, Recording.filtered(unit: "7301").count
    assert_equal 2, Recording.filtered(from: "2026-10-17", to: "2026-10-17").count
    assert_equal 0, Recording.filtered(from: "2026-10-18").count
  end
end

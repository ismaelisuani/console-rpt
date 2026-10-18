require "test_helper"

class PaginatableTest < ActiveSupport::TestCase
  setup do
    30.times { |i| Unit.create!(identifier: "9#{i}", decoder: "DTMF", name: "Unit #{i}") }
  end

  test "pages and what the navigation needs" do
    page = Unit.ordered.paginate(2, per: 10)
    assert_equal 10, page.records.size
    assert_equal [ 2, 31, 4 ], [ page.number, page.total_count, page.total_pages ]
    assert_equal [ 1, 3 ], [ page.previous_page, page.next_page ]
    assert_equal [ 11, 20 ], [ page.first_index, page.last_index ]
  end

  test "out-of-range pages land on the first or last one" do
    assert_equal 4, Unit.paginate(99, per: 10).number
    assert_equal 1, Unit.paginate("x", per: 10).number
    assert_nil Unit.paginate(4, per: 10).next_page
  end
end

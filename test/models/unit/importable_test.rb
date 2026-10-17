require "test_helper"

class Unit::ImportableTest < ActiveSupport::TestCase
  def import(csv)
    Unit.import(StringIO.new(csv))
  end

  test "creates and updates units, with either separator" do
    result = import("identifier;decoder;name;person;fleet;active\n7301;mototrbo;Mobile 12b;;North;\n215;CCIR;Patrol 4;Sgt. Gomez;Police;true\n")

    assert_equal [ 1, 1, [] ], [ result.created, result.updated, result.errors ]
    assert_equal "Mobile 12b", units(:mobile).reload.name
    assert Unit.lookup("CCIR", "215").active?
  end

  test "saves nothing when a line is wrong" do
    result = import("identifier,decoder,name\n1,P25,One\n2,Unknown,Two\n")

    assert_equal 1, result.errors.size
    assert_nil Unit.lookup("P25", "1")
  end
end

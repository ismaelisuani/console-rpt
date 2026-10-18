require "test_helper"

class Radio::LiveStateTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  setup do
    @radio = radios(:base)
  end

  def rpt_event(type, value, **headers)
    { "Event" => "RptEvent", "Node" => @radio.node, "Type" => type, "Who" => @radio.node, "Value" => value }.merge(headers)
  end

  test "a reception that identifies itself names who is talking" do
    @radio.apply_rpt_event(rpt_event("RPTKEY", "KEY", "Direction" => "RX"))
    @radio.apply_rpt_event(rpt_event("UNITID", "7301", "Decoder" => "Mototrbo"))

    assert @radio.receiving?
    assert @radio.talking_unit_identified?
    assert_equal units(:mobile), @radio.last_unit
    reception = @radio.radio_events.find_by!(kind: "receive_start")
    assert_equal "7301", reception.unit_identifier
    assert_equal 1, @radio.radio_events.count
  end

  test "a unit id just before the reception still identifies it" do
    @radio.apply_rpt_event(rpt_event("UNITID", "43981", "Decoder" => "P25"))
    @radio.apply_rpt_event(rpt_event("RPTKEY", "KEY", "Direction" => "RX"))

    assert @radio.talking_unit_identified?
    assert_equal "43981", @radio.radio_events.find_by!(kind: "receive_start").unit_identifier
  end

  test "a reception or transmission that ends looks for its recording" do
    @radio.apply_rpt_event(rpt_event("RPTKEY", "KEY", "Direction" => "RX"))
    assert_enqueued_with(job: RecordingsSyncJob, args: [ @radio.server_id ]) do
      @radio.apply_rpt_event(rpt_event("RPTKEY", "UNKEY", "Direction" => "RX"))
    end
  end

  test "transmissions keep who keyed them up" do
    @radio.apply_rpt_event(rpt_event("RPTKEY", "KEY", "Direction" => "TX", "Who" => "2000"))
    assert @radio.transmitting?
    assert_equal "2000", @radio.transmitted_by

    @radio.apply_rpt_event(rpt_event("RPTKEY", "UNKEY", "Direction" => "TX", "Who" => "2000"))
    assert_not @radio.transmitting?
    assert_nil @radio.transmitted_by
  end

  test "links, monitor ones and who asked for them" do
    LinkRequest.remember(@radio, "2000", users(:dispatcher))
    @radio.apply_rpt_event(rpt_event("LINKS", "2,2000,2010", "Monitor" => "2010"))

    assert_equal [ { "node" => "2000", "mode" => "transceive" }, { "node" => "2010", "mode" => "monitor" } ], @radio.links
    linked = @radio.radio_events.where(kind: "linked").order(:other_node)
    assert_equal %w[2000 2010], linked.map(&:other_node)
    assert_equal users(:dispatcher), linked.first.user
    assert_nil linked.last.user

    @radio.apply_rpt_event(rpt_event("LINKS", "0", "Monitor" => ""))
    assert_empty @radio.links
    assert_equal 2, @radio.radio_events.where(kind: "unlinked").count
  end

  test "links from rpt nodes on connect" do
    @radio.links_from_node_list("T2000, R2010, C2020")
    assert_equal [ { "node" => "2000", "mode" => "transceive" }, { "node" => "2010", "mode" => "monitor" } ], @radio.links

    @radio.links_from_node_list("\n*** CONNECTED NODES ***\n\n2000\n")
    assert_equal [ { "node" => "2000", "mode" => "transceive" } ], @radio.links

    @radio.links_from_node_list("\n*** CONNECTED NODES ***\n\n<NONE>\n")
    assert_empty @radio.links
  end

  test "a server going down clears the state of its radios" do
    @radio.update!(receiving: true, transmitting: true)
    server = @radio.server
    server.mark_online!(false)

    assert_not @radio.reload.receiving?
    assert_not @radio.transmitting?
    assert @radio.radio_events.exists?(kind: "server_offline")
  end
end

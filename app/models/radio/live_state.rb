# The live state of the node from the AMI RptEvent events (RPTKEY, UNITID;
# LINKS in Radio::Links): receiving, transmitting and who, the last unit ID.
# Every change is logged as a RadioEvent and pushed to the dispatch screens.
module Radio::LiveState
  extend ActiveSupport::Concern

  # A unit ID that arrives this long before the receiver keys up still
  # identifies that reception (P25 sends it first)
  UNIT_LEAD = 3.seconds
  # PTT pressed on the console this recently names the transmission
  CONSOLE_PTT_WINDOW = 5.seconds
  # app_rpt writes a recording's .txt when it ends: look for it shortly after
  RECORDING_DELAY = 3.seconds

  def apply_rpt_event(event)
    case event["Type"]
    when "RPTKEY" then event["Direction"] == "TX" ? transmitter_keyed(event) : receiver_keyed(event)
    when "UNITID" then unit_identified(event)
    when "LINKS" then links_reported(event)
    end
  end

  def server_status_changed!(online)
    update!(receiving: false, transmitting: false, transmitted_by: nil, transmitted_by_user: nil) unless online
    log_event(online ? "server_online" : "server_offline")
    broadcast_state
  end

  # The console user who pressed PTT
  def ptt_pressed_by!(user)
    update_columns(ptt_user_id: user.id, ptt_at: Time.current)
  end

  def console_transmitter(now = Time.current)
    ptt_user if ptt_at && ptt_at >= now - CONSOLE_PTT_WINDOW
  end

  # The unit of the reception going on, when it identified itself
  def talking_unit_identified?
    receiving? && unit_identified_at.present? && receiving_since.present? &&
      unit_identified_at >= receiving_since - UNIT_LEAD
  end

  def last_unit
    return if last_unit_identifier.blank?

    @last_unit ||= Unit.lookup(last_decoder, last_unit_identifier)
  end

  private
    def receiver_keyed(event)
      keyed = event["Value"] == "KEY"
      return if receiving? == keyed

      now = Time.current
      update!(receiving: keyed, receiving_since: now, last_activity_at: now)
      recording_finished unless keyed
      if keyed
        recent = unit_identified_at && unit_identified_at >= now - UNIT_LEAD
        log_event("receive_start", unit_identifier: (last_unit_identifier if recent), decoder: (last_decoder if recent))
      end
      broadcast_state
    end

    def transmitter_keyed(event)
      keyed = event["Value"] == "KEY"
      return if transmitting? == keyed

      now = Time.current
      who = event["Who"].presence
      # Blank (the node itself) or a phone-mode link ("0..."): maybe the console
      console_user = console_transmitter(now) if keyed && (who.nil? || who.start_with?("0"))
      who = nil if console_user || who&.start_with?("0")
      update!(transmitting: keyed, transmitted_by: (who if keyed), transmitted_by_user: (console_user if keyed),
        transmitting_since: now, last_activity_at: now)
      log_event("transmit_start", other_node: who, user: console_user) if keyed
      recording_finished unless keyed
      broadcast_state
    end

    def unit_identified(event)
      now = Time.current
      @last_unit = nil
      update!(last_unit_identifier: event["Value"], last_decoder: event["Decoder"], unit_identified_at: now, last_activity_at: now)
      reception = current_reception
      if reception && reception.unit_identifier.blank?
        reception.update!(unit_identifier: event["Value"], decoder: event["Decoder"])
      else
        log_event("unit_identified", unit_identifier: event["Value"], decoder: event["Decoder"])
      end
      broadcast_state
    end

    def current_reception
      return unless receiving?

      radio_events.where(kind: "receive_start").where(occurred_at: (receiving_since - 1.second)..).recent.first
    end

    def recording_finished
      RecordingsSyncJob.set(wait: RECORDING_DELAY).perform_later(server_id)
    end

    def log_event(kind, **attributes)
      radio_events.create!(kind: kind, server: server, **attributes)
    end
end

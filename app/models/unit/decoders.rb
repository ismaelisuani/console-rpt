# Units are identified by the ID that app_rpt decodes and the decoder name it
# sends in the AMI UNITID events
module Unit::Decoders
  extend ActiveSupport::Concern

  DECODERS = %w[Mototrbo P25 MDC1200 DTMF CCIR EEA EIA ZVEI1 ZVEI2 ZVEI3].freeze

  included do
    validates :decoder, inclusion: { in: DECODERS }
  end

  class_methods do
    def lookup(decoder, identifier)
      active.find_by(decoder: decoder, identifier: identifier)
    end

    # The decoder as app_rpt names it, whatever the case
    def decoder_named(name)
      DECODERS.find { |decoder| decoder.casecmp?(name.to_s.strip) } || name
    end
  end
end

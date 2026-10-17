# The radios a user sees and what they can do on each, from the radio groups
# they were given (to operate or only to listen)
module User::RadioAccess
  extend ActiveSupport::Concern

  def radios
    return Radio.all if all_radios?

    Radio.where(id: RadioGroupMembership.where(radio_group_id: radio_group_accesses.select(:radio_group_id)).select(:radio_id))
  end

  def visible_radio_groups
    return RadioGroup.all if all_radios?

    RadioGroup.where(id: radio_group_accesses.select(:radio_group_id))
  end

  # :operate, :listen or nil
  def access_to(radio)
    return :operate if all_radios?

    levels = radio_group_accesses
      .where(radio_group_id: RadioGroupMembership.where(radio_id: radio.id).select(:radio_group_id))
      .pluck(:level)
    if levels.include?("operate") then :operate
    elsif levels.any? then :listen
    end
  end

  def can_listen_to?(radio)
    can?(:listen) && access_to(radio).present?
  end

  def can_transmit_on?(radio)
    can?(:transmit) && access_to(radio) == :operate
  end

  def can_connect?(radio)
    can?(:connect) && access_to(radio) == :operate
  end

  # { radio_group_id => "operate" | "listen" }, as the user form edits it
  def group_levels
    radio_group_accesses.reject(&:marked_for_destruction?).to_h { |access| [ access.radio_group_id, access.level ] }
  end

  def group_levels=(levels)
    levels.to_h.each do |group_id, level|
      access = radio_group_accesses.find { |a| a.radio_group_id == group_id.to_i }
      if RadioGroupAccess::LEVELS.include?(level)
        access ? access.level = level : radio_group_accesses.build(radio_group_id: group_id.to_i, level: level)
      elsif access
        access.mark_for_destruction
      end
    end
  end
end

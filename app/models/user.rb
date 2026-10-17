class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  belongs_to :role
  has_many :radio_group_accesses, dependent: :destroy, autosave: true
  has_many :radio_groups, through: :radio_group_accesses

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :name, presence: true
  validates :email_address, presence: true, uniqueness: true
  validates :locale, inclusion: { in: ->(_) { I18n.available_locales.map(&:to_s) } }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:name) }

  def can?(permission)
    role.grants?(permission)
  end

  # Radio administrators see and operate every radio; everybody else, the
  # radios of the groups they were given
  def all_radios?
    can?(:manage_radios)
  end

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

  def can_listen_to?(radio)
    can?(:listen) && access_to(radio).present?
  end

  def can_transmit_on?(radio)
    can?(:transmit) && access_to(radio) == :operate
  end

  def can_connect?(radio)
    can?(:connect) && access_to(radio) == :operate
  end
end

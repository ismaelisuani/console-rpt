# Nobody can turn off or delete their own user
module User::SelfProtection
  extend ActiveSupport::Concern

  included do
    validate :not_deactivating_self
    before_destroy :not_destroying_self
  end

  def current?
    Current.user == self
  end

  private
    def not_deactivating_self
      errors.add(:active, :self) if current? && !active?
    end

    def not_destroying_self
      return unless current?

      errors.add(:base, :destroy_self)
      throw :abort
    end
end

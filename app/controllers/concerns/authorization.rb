module Authorization
  extend ActiveSupport::Concern

  included do
    helper_method :can?
  end

  class_methods do
    def require_permission(permission, **options)
      before_action(**options) { require_permission!(permission) }
    end
  end

  private
    def can?(permission)
      Current.user&.can?(permission)
    end

    def require_permission!(permission)
      return if can?(permission)

      respond_to do |format|
        format.html { redirect_to home_path, alert: t("authorization.denied") }
        format.any { head :forbidden }
      end
    end

    # The first page the user is allowed to see
    def home_path
      if can?(:view_dispatch) then dispatch_path
      else profile_path
      end
    end
end

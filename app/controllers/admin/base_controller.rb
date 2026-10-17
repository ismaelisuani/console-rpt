module Admin
  class BaseController < ApplicationController
    private
      def redirect_saved(path, record, action)
        redirect_to path, notice: t("flash.#{action}", resource: record.class.model_name.human)
      end

      def destroy_record(record, path)
        if record.destroy
          redirect_saved(path, record, :destroyed)
        else
          redirect_to path, alert: record.errors.full_messages.to_sentence
        end
      end
  end
end

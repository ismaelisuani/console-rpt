class ContactsController < ApplicationController
  require_permission :phone
  before_action :set_contact, only: %i[edit update destroy]

  def index
    @query = params[:q].to_s.strip
    @page = Contact.search(@query).ordered.includes(:contact_favorites).paginate(params[:page])
  end

  def new
    @contact = Contact.new
  end

  def create
    @contact = Contact.new(contact_params)
    if @contact.save
      redirect_to contacts_path, notice: t("flash.created", resource: Contact.model_name.human)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @contact.update(contact_params)
      redirect_to contacts_path, notice: t("flash.updated", resource: Contact.model_name.human)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @contact.destroy
    redirect_to contacts_path, notice: t("flash.destroyed", resource: Contact.model_name.human)
  end

  private
    def set_contact
      @contact = Contact.find(params.expect(:id))
    end

    def contact_params
      params.expect(contact: %i[name number organization])
    end
end

# Users sign in with their username or, if they have one, their email address
module User::Authentication
  extend ActiveSupport::Concern

  USERNAME_FORMAT = /\A[a-z0-9._-]+\z/

  included do
    has_secure_password

    normalizes :username, with: ->(username) { username.strip.downcase }
    normalizes :email_address, with: ->(email) { email.strip.downcase.presence }

    validates :username, presence: true, uniqueness: true, length: { in: 2..50 }, format: { with: USERNAME_FORMAT }
    validates :email_address, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_nil: true
  end

  class_methods do
    def authenticate_login(login, password)
      login = login.to_s.strip.downcase
      return if login.empty? || password.blank?

      attribute = login.include?("@") ? :email_address : :username
      authenticate_by(attribute => login, password: password)
    end
  end
end

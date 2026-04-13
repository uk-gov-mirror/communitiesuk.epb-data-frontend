module UseCase
  class SendEmailToUsers
    def initialize(user_credentials_gateway:, notify_gateway:)
      @user_credentials_gateway = user_credentials_gateway
      @notify_gateway = notify_gateway
    end

    def execute(notify_template_id)
      emails = @user_credentials_gateway.get_opt_in_users
      emails.each do |email|
        @notify_gateway.send_email(template_id: notify_template_id, email_address: email)
      end
    end
  end
end

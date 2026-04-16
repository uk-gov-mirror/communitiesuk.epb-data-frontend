desc "Send users an email"
task :send_email_to_users do
  production_send = ENV["PRODUCTION_SEND"] || false
  test_users = ENV["TEST_USERS"]
  template_id = ENV["NOTIFY_DATA_EMAIL_USERS_TEMPLATE_ID"]
  service_domain = ENV["SERVICE_DOMAIN"]

  if !production_send && test_users.nil?
    raise Errors::SendEmailToUsersError, "ENV variable PRODUCTION_SEND ENV must set as true"
  end

  notify_client = Notifications::Client.new(ENV["NOTIFY_DATA_API_KEY"])
  kms_gateway = Gateway::KmsGateway.new
  user_credentials_gateway = test_users.nil? ? Gateway::UserCredentialsGateway.new(kms_gateway: kms_gateway) : Helper::StubUsersCredentials.new(test_users)

  notify_gateway = Gateway::NotifyGateway.new(notify_client)

  UseCase::SendEmailToUsers.new(user_credentials_gateway:, notify_gateway:).execute(template_id, service_domain)
end

require "notifications/client"

module Gateway
  class NotifyGateway
    def initialize(notify_client)
      @client = notify_client
    end

    def send_opt_out_email(template_id:, destination_email:, email:, is_test:, name:, owner_or_occupier:, certificate_number:, address_line1:, address_line2:, town:, postcode:)
      response = @client.send_email(
        email_address: destination_email,
        template_id:,
        personalisation: {
          is_test:,
          name:,
          email:,
          owner_or_occupier:,
          certificate_number:,
          address: [address_line1, address_line2, town, postcode].reject(&:empty?).join(", "),
        },
      )

      response.id
    rescue Notifications::Client::BadRequestError, Notifications::Client::AuthError, Notifications::Client::RateLimitError => e
      raise Errors::NotifySendEmailError, e.message
    rescue Notifications::Client::ServerError
      raise Errors::NotifyServerError
    end

    def send_email(template_id:, email_address:, service_domain:)
      response = @client.send_email(
        email_address:,
        template_id:,
        unsubscribe_link: "https://#{service_domain}/api/my-account/toggle-email-notifications",
      )
      response.id
    rescue Notifications::Client::BadRequestError, Notifications::Client::AuthError => e
      raise Errors::NotifySendEmailError, e.message
    rescue Notifications::Client::RateLimitError
      raise Errors::NotifyRateLimit
    rescue Notifications::Client::ServerError
      raise Errors::NotifyServerError
    end

    def check_email_status(notification_id)
      @client.get_notification(notification_id).status
    end
  end
end

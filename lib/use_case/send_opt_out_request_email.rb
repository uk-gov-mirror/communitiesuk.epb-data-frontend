module UseCase
  class SendOptOutRequestEmail
    def initialize(notify_gateway:)
      @notify_gateway = notify_gateway
      @template_id = ENV["NOTIFY_OPT_OUT_TEMPLATE_ID"]
      @is_test = ENV["STAGE"] != "production"
      @opt_outs_email = ENV["NOTIFY_OPT_OUT_EMAIL_RECIPIENT"]
    end

    def execute(name:, email:, certificate_number:, owner_or_occupier:, address_line1:, address_line2:, town:, postcode:)
      @notify_gateway.send_opt_out_email(
        destination_email: email,
        is_test: @is_test, template_id: @template_id,
        name:, email:, certificate_number:, owner_or_occupier:, address_line1:, address_line2:, town:, postcode:
      )

      unless @is_test
        @notify_gateway.send_opt_out_email(
          destination_email: @opt_outs_email,
          is_test: @is_test, template_id: @template_id,
          name:, email:, certificate_number:, owner_or_occupier:, address_line1:, address_line2:, town:, postcode:
        )
      end
    end
  end
end

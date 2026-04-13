describe Gateway::NotifyGateway do
  subject(:gateway) { described_class.new(notify_client) }

  let(:notify_client) do
    Notifications::Client.new(ENV["NOTIFY_DATA_API_KEY"])
  end

  let(:template_id) do
    "f5d03031-b559-4264-8503-802ee0e78f4c"
  end

  let(:email_address) { "sender@something.com" }
  let(:personalisation) do
    {
      is_test: true,
      name: "John Smith",
      email: email_address,
      owner_or_occupier: "Owner",
      certificate_number: "1234-1234-1234-1234-1234",
      address_line1: "Flat 3",
      address_line2: "5 Bob Lane",
      town: "Testerton",
      postcode: "TE57 1NG",
    }
  end

  let(:personalisation_with_empty_values) do
    {
      is_test: true,
      name: "John Smith",
      email: email_address,
      owner_or_occupier: "Owner",
      certificate_number: "1234-1234-1234-1234-1234",
      address_line1: "Flat 3",
      address_line2: "",
      town: "",
      postcode: "TE57 1NG",
    }
  end

  let(:send_email_api_response) do
    {
      "id": "201b576e-c09b-467b-9dfa-9c3b689ee730",

      "template": {
        "id": template_id,
        "version": 2,
        "uri": "https://api.notifications.service.gov.uk/v2/template/#{template_id}",
      },
    }
  end

  let(:check_status_api_response) do
    {
      "email_address": email_address,
      "type": "email",
      "status": "delivered",
    }
  end

  before do
    WebMock.stub_request(:post, "https://api.notifications.service.gov.uk/v2/notifications/email")
           .to_return(status: 200, body: send_email_api_response.to_json, headers: {})
  end

  describe "#send_opt_out_email" do
    context "when Notification service responds successfully with 200" do
      it "sends an email" do
        expect(gateway.send_opt_out_email(template_id:, destination_email: email_address, **personalisation)).to eq("201b576e-c09b-467b-9dfa-9c3b689ee730")
        expect(WebMock).to have_requested(
          :post,
          "https://api.notifications.service.gov.uk/v2/notifications/email",
        ).with(
          body: '{"email_address":"sender@something.com","template_id":"f5d03031-b559-4264-8503-802ee0e78f4c","personalisation":{"is_test":true,"name":"John Smith","email":"sender@something.com","owner_or_occupier":"Owner","certificate_number":"1234-1234-1234-1234-1234","address":"Flat 3, 5 Bob Lane, Testerton, TE57 1NG"}}',
        )
      end
    end

    context "when there are empty values in the address" do
      it "sends an email with the correct personalisation" do
        expect(gateway.send_opt_out_email(template_id:, destination_email: email_address, **personalisation_with_empty_values)).to eq("201b576e-c09b-467b-9dfa-9c3b689ee730")
        expect(WebMock).to have_requested(
          :post,
          "https://api.notifications.service.gov.uk/v2/notifications/email",
        ).with(
          body: '{"email_address":"sender@something.com","template_id":"f5d03031-b559-4264-8503-802ee0e78f4c","personalisation":{"is_test":true,"name":"John Smith","email":"sender@something.com","owner_or_occupier":"Owner","certificate_number":"1234-1234-1234-1234-1234","address":"Flat 3, TE57 1NG"}}',
        )
      end
    end

    context "when the Notification service responds with 400 error" do
      before do
        WebMock.stub_request(:post, "https://api.notifications.service.gov.uk/v2/notifications/email")
               .to_return(status: 400, body: "BadRequestError: Cannot send to this recipient using a team-only API key.", headers: {})
      end

      it "raises an NotifySendEmailError" do
        expect { gateway.send_opt_out_email(template_id:, destination_email: email_address, **personalisation) }.to raise_error(Errors::NotifySendEmailError, "BadRequestError: Cannot send to this recipient using a team-only API key.")
      end
    end

    context "when the Notification service responds with 500 error" do
      before do
        WebMock.stub_request(:post, "https://api.notifications.service.gov.uk/v2/notifications/email")
               .to_return(status: 500, body: "Exception: Internal server error", headers: {})
      end

      it "raises an NotifyServerError" do
        expect { gateway.send_opt_out_email(template_id:, destination_email: email_address, **personalisation) }.to raise_error(Errors::NotifyServerError)
      end
    end
  end

  describe "#check_email_status" do
    before do
      WebMock.stub_request(:get, "https://api.notifications.service.gov.uk/v2/notifications/#{notification_id}")
             .to_return(status: 200, body: check_status_api_response.to_json, headers: {})
    end

    let(:notification_id) do
      gateway.send_opt_out_email(template_id:, destination_email: email_address, **personalisation)
    end

    it "confirms delivery status of the email" do
      expect(gateway.check_email_status(notification_id)).to eq("delivered")
      expect(WebMock).to have_requested(
        :get,
        "https://api.notifications.service.gov.uk/v2/notifications/#{notification_id}",
      )
    end
  end

  describe "#send_email" do
    context "when Notification service responds successfully with 200" do
      it "returns the response id" do
        expect(gateway.send_email(template_id:, email_address:)).to eq("201b576e-c09b-467b-9dfa-9c3b689ee730")
      end

      it "a message is sent to the nofiy api" do
        gateway.send_email(template_id:, email_address:)
        expect(WebMock).to have_requested(
          :post,
          "https://api.notifications.service.gov.uk/v2/notifications/email",
        ).with(
          body: '{"email_address":"sender@something.com","template_id":"f5d03031-b559-4264-8503-802ee0e78f4c"}',
        )
      end
    end

    context "when the rate limit is reached" do
      before do
        WebMock.stub_request(:post, "https://api.notifications.service.gov.uk/v2/notifications/email")
               .to_return(status: 429, body: "exceeded rate limit for key type TEAM of 10 requests per 10 seconds", headers: {})
      end

      it "re-raises the rate limit error" do
        expect { gateway.send_email(template_id:, email_address:) }.to raise_error Errors::NotifyRateLimit
      end
    end
  end
end

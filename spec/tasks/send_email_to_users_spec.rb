require "notifications/client"

describe "Sending emails to users" do
  context "when calling the rake task" do
    subject(:task) { get_task("send_email_to_users") }

    let(:test_user_emails) do
      "dave@test.com, jo@test.com"
    end

    let(:service_domain) do
      "get-energy-performance-data.epb-frontend"
    end

    let(:notify_client) do
      instance_double(Notifications::Client)
    end

    let(:kms_gateway) do
      instance_double(Gateway::KmsGateway)
    end

    let(:user_credentials_gateway) do
      instance_double(Gateway::UserCredentialsGateway)
    end

    let(:notify_gateway) do
      instance_double(Gateway::NotifyGateway)
    end

    let(:stub_users) do
      instance_double(Helper::StubUsersCredentials)
    end

    before do
      allow(Notifications::Client).to receive(:new).and_return(notify_client)
      allow(Gateway::KmsGateway).to receive(:new).and_return(kms_gateway)
      allow(Gateway::NotifyGateway).to receive(:new).with(notify_client).and_return(notify_gateway)
      allow(Helper::StubUsersCredentials).to receive(:new).and_return(stub_users)
      allow(Gateway::UserCredentialsGateway).to receive(:new).and_return(user_credentials_gateway)

      allow(notify_gateway).to receive(:send_email)
      allow(stub_users).to receive(:get_opt_in_users).and_return(test_user_emails.split(","))
      allow(user_credentials_gateway).to receive(:get_opt_in_users).and_return(test_user_emails.split(","))
      ENV["NOTIFY_DATA_EMAIL_USERS_TEMPLATE_ID"] = "some_template_id"
      ENV["SERVICE_DOMAIN"] = service_domain
    end

    after do
      ENV.delete("NOTIFY_EMAIL_USERS_TEMPLATE_ID")
      ENV.delete("SERVICE_DOMAIN")
    end

    context "when sending messages to emails passed as an ENV variable" do
      before do
        ENV["TEST_USERS"] = test_user_emails
        task.invoke
      end

      after do
        ENV.delete("TEST_USERS")
      end

      it "calls the StubUsersCredentials class to inject users into the use case" do
        expect(stub_users).to have_received(:get_opt_in_users)
      end

      it "does not get data from dynam db" do
        expect(user_credentials_gateway).not_to have_received(:get_opt_in_users)
      end

      it "sends emails to stubbed users" do
        test_user_emails.split(",").each do |email|
          expect(notify_gateway).to have_received(:send_email).with({ email_address: email, template_id: "some_template_id", service_domain: service_domain }).exactly(1).times
        end
      end
    end

    context "when sending production emails extracted from AWS" do
      before do
        ENV["PRODUCTION_SEND"] = "true"
        task.invoke
      end

      after do
        ENV.delete("PRODUCTION_SEND")
      end

      it "extracts users from Dynamo db" do
        expect(user_credentials_gateway).to have_received(:get_opt_in_users)
      end

      it "sends emails users" do
        test_user_emails.split(",").each do |email|
          expect(notify_gateway).to have_received(:send_email).with({ email_address: email, template_id: "some_template_id", service_domain: service_domain }).exactly(1).times
        end
      end
    end

    context "when attempting to send production emails without correct ENV vars" do
      it "raises an error" do
        expect { task.invoke }.to raise_error Errors::SendEmailToUsersError
      end

      it "does not send any emails" do
        expect(notify_gateway).not_to have_received(:send_email)
      end
    end
  end
end

describe UseCase::SendEmailToUsers do
  let(:user_credentials_gateway) do
    instance_double(Gateway::UserCredentialsGateway)
  end

  let(:notify_gateway) do
    instance_double(Gateway::NotifyGateway)
  end

  let(:template_id) { "template_id" }

  let(:use_case) do
    described_class.new(user_credentials_gateway:, notify_gateway:)
  end

  describe "#execute" do
    let(:emails) do
      %w[test@email.com name.test@email.com]
    end

    before do
      allow(user_credentials_gateway).to receive(:get_opt_in_users).and_return emails
      allow(notify_gateway).to receive(:send_email)
      use_case.execute(template_id)
    end

    it "extracts the decrypted emails addresses" do
      expect(user_credentials_gateway).to have_received(:get_opt_in_users).exactly(1).times
    end

    it "sends message to notify for each user" do
      emails.each do |email|
        expect(notify_gateway).to have_received(:send_email).with(template_id:, email_address: email).exactly(1).times
      end
    end

    context "when sending one of the emails raises an decrypt error" do
      let(:bad_email) do
        "bad.email@test.com"
      end

      before do
        emails.insert(1, bad_email)
        allow(notify_gateway).to receive(:send_email).with(template_id: template_id, email_address: bad_email).and_raise(Errors::NotifySendEmailError)
      end

      it "skips over the error and sends emails to the rest" do
        expect(notify_gateway).to have_received(:send_email).exactly(2).times
      end
    end

    context "when the rate limit is reached" do
      before do
        allow(notify_gateway).to receive(:send_email).and_raise(Errors::NotifyRateLimit)
      end

      it "the error is bubbled up to the use case" do
        expect { use_case.execute(template_id) }.to raise_error(Errors::NotifyRateLimit)
      end
    end
  end
end

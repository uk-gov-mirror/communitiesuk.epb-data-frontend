describe UseCase::SendOptOutRequestEmail do
  let(:notify_gateway) do
    instance_double(Gateway::NotifyGateway)
  end

  let(:use_case) do
    described_class.new(notify_gateway:)
  end

  let(:opt_out_request_data) do
    {
      name: "John Smith",
      email: "user@example.com",
      owner_or_occupier: "Owner",
      certificate_number: "1234-1234-1234-1234-1234",
      address_line1: "Flat 3",
      address_line2: "5 Bob Lane",
      town: "Testerton",
      postcode: "TE57 1NG",
    }
  end

  describe "#execute" do
    before do
      allow(notify_gateway).to receive(:send_opt_out_email)
      use_case.execute(**opt_out_request_data)
    end

    context "when a user sends an opt-out request in pre-production" do
      around do |example|
        original_stage = ENV["STAGE"]
        ENV["STAGE"] = "staging"
        example.run
        ENV["STAGE"] = original_stage
      end

      it "calls the notify_gateway method to send email to user setting 'is_test' to true" do
        expect(notify_gateway).to have_received(:send_opt_out_email).with(
          template_id: "f5d03031-b559-4264-8503-802ee0e78f4c",
          destination_email: "user@example.com",
          is_test: true,
          **opt_out_request_data,
        )
      end

      it "calls the notify_gateway method to send email to opt-outs email address setting 'is_test' to true" do
        expect(notify_gateway).not_to have_received(:send_opt_out_email).with(
          template_id: "f5d03031-b559-4264-8503-802ee0e78f4c",
          destination_email: "opt-outs@example.com",
          is_test: true,
          **opt_out_request_data,
        )
      end
    end

    context "when a user sends an opt-out request in production" do
      around do |example|
        original_stage = ENV["STAGE"]
        ENV["STAGE"] = "production"
        example.run
        ENV["STAGE"] = original_stage
      end

      it "calls the notify_gateway method to send email to user" do
        expect(notify_gateway).to have_received(:send_opt_out_email).with(
          template_id: "f5d03031-b559-4264-8503-802ee0e78f4c",
          destination_email: "user@example.com",
          is_test: false,
          **opt_out_request_data,
        )
      end

      it "calls the notify_gateway method to send email to opt-outs email address" do
        expect(notify_gateway).to have_received(:send_opt_out_email).with(
          template_id: "f5d03031-b559-4264-8503-802ee0e78f4c",
          destination_email: "opt-outs@example.com",
          is_test: false,
          **opt_out_request_data,
        )
      end
    end
  end
end

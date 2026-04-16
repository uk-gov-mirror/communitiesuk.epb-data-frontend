describe UseCase::DeleteUser do
  let(:user_credentials_gateway) do
    instance_double(Gateway::UserCredentialsGateway)
  end

  let(:use_case) do
    described_class.new(user_credentials_gateway:)
  end

  let(:test_user_id) { "test-user-id" }

  describe "#execute" do
    context "when calling the use case" do
      before do
        allow(user_credentials_gateway).to receive(:delete_user).and_return({})
      end

      it "calls delete_user on the gateway" do
        use_case.execute(test_user_id)
        expect(user_credentials_gateway).to have_received(:delete_user).with(test_user_id).exactly(:once)
      end
    end
  end
end

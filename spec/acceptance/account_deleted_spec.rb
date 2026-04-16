describe "Acceptance::AccountDeleted", type: :feature do
  include RSpecFrontendServiceMixin

  let(:local_host) do
    "http://get-energy-performance-data"
  end

  let(:delete_user_use_case) { instance_double(UseCase::DeleteUser) }

  let(:app) do
    fake_container = instance_double(Container)
    allow(fake_container).to receive(:get_object).with(:delete_user_use_case).and_return(delete_user_use_case)

    Rack::Builder.new do
      use Rack::Session::Cookie, secret: "test" * 16
      run Controller::ApiController.new(container: fake_container)
    end
  end

  describe "get /account-deleted" do
    context "when accessed via the correct referrer" do
      before do
        header "Referer", "#{local_host}/api/my-account/delete-account"
        get "#{local_host}/account-deleted"
      end

      it "returns status 200" do
        expect(last_response.status).to eq(200)
      end

      it "has the correct header" do
        expect(last_response.body).to have_css("h1.govuk-heading-xl", text: "Delete your account")
      end

      it "shows the confirmation message" do
        expect(last_response.body).to include("Your account has been deleted")
      end

      it "does not have a back link to the account page" do
        expect(last_response.body).not_to have_css("a.govuk-back-link")
      end
    end

    context "when accessed without a valid referrer" do
      before do
        get "#{local_host}/account-deleted"
      end

      it "returns 403 forbidden" do
        expect(last_response.status).to eq(403)
      end
    end
  end
end

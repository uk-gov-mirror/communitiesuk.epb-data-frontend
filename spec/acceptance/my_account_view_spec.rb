describe "Acceptance::MyAccount", type: :feature do
  include RSpecFrontendServiceMixin

  let(:local_host) do
    "http://get-energy-performance-data/api/my-account"
  end

  let(:response) { get local_host }

  let(:get_user_info_use_case) do
    instance_double(UseCase::GetUserInfo)
  end

  let(:toggle_email_notifications_use_case) do
    instance_double(UseCase::ToggleUserEmailNotifications)
  end

  let(:app) do
    fake_container = instance_double(Container)
    allow(fake_container).to receive(:get_object).with(:get_user_info_use_case).and_return(get_user_info_use_case)
    allow(fake_container).to receive(:get_object).with(:toggle_email_notifications_use_case).and_return(toggle_email_notifications_use_case)

    Rack::Builder.new do
      use Rack::Session::Cookie, secret: "test" * 16
      run Controller::ApiController.new(container: fake_container)
    end
  end

  describe "get .get-energy-certificate-data.epb-frontend/api/my-account" do
    before do
      allow(get_user_info_use_case).to receive(:execute).and_return({ bearer_token: "mock_value", opt_out: false })
      allow(Helper::Session).to receive_messages(is_user_authenticated?: true, get_email_from_session: "test@email.com")
      allow(ViewModels::MyAccount).to receive_messages(
        get_bearer_token: "kfhbks750D0RnC2oKGsoM936wKmtd4ZcoSw489rPo4FDqQ2SYQVtVnQ4PhZ33b46YZPNZXo6r",
        get_opt_out: false,
        get_opt_out_description: "Currently opted out",
      )
    end

    context "when the my account page is rendered" do
      it "returns status 200" do
        expect(response.status).to eq(200)
      end

      it "shows a back link" do
        header "Referer", "/previous_page"
        expect(response.body).to have_link("Back", href: "/previous_page")
      end

      it "has the correct page header" do
        expect(response.body).to have_css("h1.govuk-heading-xl", text: "My account")
      end

      it "displays the title the same as the main header value" do
        expect(response.body).to have_title "My account – GOV.UK"
      end

      it "shows the email address table row" do
        expect(response.body).to have_css("#email-address.govuk-summary-list__row")
      end

      it "shows the bearer token table row" do
        expect(response.body).to have_css("#bearer-token.govuk-summary-list__row")
      end

      it "shows the sign out link on email table row" do
        expect(response.body).to have_css("#email-sign-out.govuk-link")
        expect(response.body).to have_link("Sign out", href: "/sign-out")
      end

      it "shows the copy link on bearer token table row" do
        expect(response.body).to have_button("Copy")
      end

      it "shows the email address" do
        expect(response.body).to have_css("#email-address-value", text: "test@email.com")
      end

      it "shows the bearer token" do
        expect(response.body).to have_css("#bearer-token-value", text: "kfhbks750D0RnC2oKGsoM936wKmtd4ZcoSw489rPo4FDqQ2SYQVtVnQ4PhZ33b46YZPNZXo6r")
      end

      it "shows the opt out text" do
        expect(response.body).to have_css("#opt-out-value", text: "Currently opted out")
      end

      it "shows the opt out toggle link" do
        expect(response.body).to have_link("Opt-out", href: "/api/my-account/toggle-email-notifications", id: "opt-out-toggle-link")
      end

      it "shows the delete your account section" do
        expect(response.body).to have_css("h2.govuk-heading-l", text: "Delete your account")
      end

      it "shows the delete your account section content" do
        expect(response.body).to include("Deleting your account removes your data from this service.")
        expect(response.body).to include("You will no longer be able to use the service or API, and you will stop receiving email updates.")
        expect(response.body).to include("You cannot undo this action.")
      end

      it "shows the delete account button" do
        expect(response.body).to have_link("Delete account", href: "/api/my-account/delete-account")
      end

      it "redirects to /login/authorize when the bearer token is missing" do
        allow(ViewModels::MyAccount).to receive(:get_bearer_token).and_raise(Errors::BearerTokenMissing)
        expect(response).to be_redirect
        expect(response.location).to include("/login/authorize?referer=api/my-account")
      end
    end

    context "when the user is not authenticated" do
      before { allow(Helper::Session).to receive(:is_user_authenticated?).and_raise(Errors::AuthenticationError, "User is not authenticated") }

      after { allow(Helper::Session).to receive(:is_user_authenticated?).and_return(true) }

      it "redirects to the OneLogin login page" do
        expect(response).to be_redirect
        expect(response.location).to eq("http://get-energy-performance-data/login/authorize?referer=api%2Fmy-account")
      end
    end

    context "when changing the status of the user notification emails" do
      let(:response) { get "#{local_host}/toggle-email-notifications" }

      before do
        allow(toggle_email_notifications_use_case).to receive(:execute)
      end

      it "redirects to the my-account page" do
        expect(response).to be_redirect
        expect(response.location).to eq("http://get-energy-performance-data/api/my-account")
      end
    end
  end
end

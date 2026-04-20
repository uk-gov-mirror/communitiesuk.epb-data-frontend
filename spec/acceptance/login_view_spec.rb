describe "Acceptance::Login", type: :feature do
  include RSpecFrontendServiceMixin
  let(:login_url) do
    "http://get-energy-performance-data/login"
  end

  let(:callback_url) do
    "http://get-energy-performance-data/login/callback"
  end

  let(:response) { get login_url }

  let(:onelogin_gateway) do
    instance_double(Gateway::OneloginGateway)
  end

  let(:sign_onelogin_request_test_use_case) do
    instance_double(UseCase::SignOneloginRequest)
  end

  let(:request_onelogin_token_use_case) do
    instance_double(UseCase::RequestOneloginToken)
  end

  let(:get_onelogin_user_info_use_case) do
    instance_double(UseCase::GetOneloginUserInfo)
  end

  let(:get_user_id_use_case) do
    instance_double(UseCase::GetUserId)
  end

  let(:validate_id_token_use_case) do
    instance_double(UseCase::ValidateIdToken)
  end

  let(:get_user_creds_gateway) do
    instance_double(Gateway::UserCredentialsGateway)
  end

  let(:token_response_hash) do
    {
      "access_token": "SlAV32hkKG",
      "token_type": "Bearer",
      "expires_in": 180,
      "id_token": "eyJhbGciOiJSUzI1NiIsImtpZCI6IjFlOWdkazcifQ.ewogImlzcyI6ICJodHRwOi8vc2VydmVyLmV4YW1wbGUuY29tIiwKICJzdWIiOiAiMjQ4Mjg",
    }
  end

  let(:user_info_response) do
    {
      email: "test@email.com",
      email_verified: true,
      sub: "urn:fdc:gov.uk:2022:56P4CMsGh_02YOlWpd8PAOI-2sVlB2nsNU7mcLZYhYw=",
    }
  end

  let(:app) do
    fake_container = instance_double(Container)
    allow(fake_container).to receive(:get_object).with(:sign_onelogin_request_use_case).and_return(sign_onelogin_request_test_use_case)
    allow(fake_container).to receive(:get_object).with(:request_onelogin_token_use_case).and_return(request_onelogin_token_use_case)
    allow(fake_container).to receive(:get_object).with(:validate_id_token_use_case).and_return(validate_id_token_use_case)
    allow(fake_container).to receive(:get_object).with(:get_onelogin_user_info_use_case).and_return(get_onelogin_user_info_use_case)
    allow(fake_container).to receive(:get_object).with(:get_user_id_use_case).and_return(get_user_id_use_case)

    Rack::Builder.new do
      use Rack::Session::Cookie, secret: "test" * 16
      run Controller::UserController.new(container: fake_container)
    end
  end

  around do |example|
    original_stage = ENV["STAGE"]
    ENV["STAGE"] = "mock"
    example.run
    ENV["STAGE"] = original_stage
  end

  describe "get .get-energy-certificate-data.epb-frontend/login" do
    before do
      get "#{login_url}?referer=opt-out"
    end

    context "when the login page is rendered only for opt-out" do
      it "returns status 200" do
        expect(response.status).to eq(200)
      end

      it "shows the correct header and body text" do
        expect(response.body).to have_selector("h1", text: "Create your GOV.UK One Login or sign in")
        expect(response.body).to have_selector("p.govuk-body", text: "If you’ve used other government services for example, to file a Self Assessment tax return or apply for or renew a passport, you can use the same login details here.")
        expect(response.body).to have_selector("strong", text: "Self Assessment tax return")
        expect(response.body).to have_selector("strong", text: "apply for or renew a passport")
        expect(response.body).to have_selector("p.govuk-body", text: "If you don’t have a One Login, you can create one when you start.")
      end

      it "displays the title the same as the main header value" do
        expect(response.body).to have_title "Create your GOV.UK One Login or sign in – GOV.UK"
      end

      it "has the correct Start now button" do
        expect(response.body).to have_link("Start now", href: "/login/authorize?referer=opt-out")
      end
    end
  end

  describe "get .get-energy-certificate-data.epb-frontend/login/authorize" do
    context "when the request is received" do
      before do
        allow(sign_onelogin_request_test_use_case).to receive(:execute).and_return("test_signed_request")
        get "#{login_url}/authorize?referer=filter-properties%3Fproperty_type%3Ddomestic"
      end

      it "returns status 302" do
        expect(last_response.status).to eq(302)
      end

      it "redirects to the OneLogin authorization URL with the correct host and path" do
        uri = URI(last_response.headers["Location"])
        expect(uri.host).to eq(ENV["ONELOGIN_HOST_URL"].gsub("https://", ""))
        expect(uri.path).to eq("/authorize")
      end

      it "redirects to the OneLogin authorization URL with the correct query parameters" do
        uri = URI(last_response.headers["Location"])
        query_params = Rack::Utils.parse_query(uri.query)
        expect(query_params["response_type"]).to eq("code")
        expect(query_params["scope"]).to eq("openid email")
        expect(query_params["client_id"]).to eq(ENV["ONELOGIN_CLIENT_ID"])
        expect(query_params["request"]).to eq("test_signed_request")
      end

      it "does not return nil for nonce and state in session" do
        expect(last_request.session[:nonce]).not_to be_nil
        expect(last_request.session[:state]).not_to be_nil
      end

      it "sets the referer value in the session" do
        expect(last_request.session[:referer]).to eq "filter-properties?property_type=domestic"
      end

      it "calls the use case with the correct arguments" do
        expect(sign_onelogin_request_test_use_case).to have_received(:execute).with(
          aud: "#{ENV['ONELOGIN_HOST_URL']}/authorize",
          client_id: ENV["ONELOGIN_CLIENT_ID"],
          redirect_uri: "#{last_request.scheme}://#{last_request.host_with_port}/login/callback",
          state: last_request.session[:state],
          nonce: last_request.session[:nonce],
        )
      end
    end
  end

  describe "get .get-energy-certificate-data.epb-frontend/login/callback" do
    before do
      allow(request_onelogin_token_use_case).to receive(:execute).and_return(token_response_hash)
      allow(get_onelogin_user_info_use_case).to receive(:execute).and_return(user_info_response)
      allow(Helper::Onelogin).to receive(:check_one_login_errors).and_return(true)
      allow(validate_id_token_use_case).to receive(:execute).and_return(true)
      allow(Helper::Session).to receive(:set_session_value)
      allow(get_user_id_use_case).to receive(:execute).and_return("e40c46c3-4636-4a8a-abd7-be72e1a525f6")
    end

    context "when the request is received" do
      before do
        Timecop.freeze(Time.utc(2025, 6, 25, 12, 0, 0))
      end

      after do
        Timecop.return
      end

      context "when id token is valid" do
        before do
          allow(Helper::Session).to receive(:get_session_value).and_call_original
          get callback_url, { code: "test_code", state: "test_state" }, { "rack.session" => { nonce: "test_nonce", state: "test_state", referer: "test-redirect-path" } }
        end

        it "calls the request_onelogin_token_use_case with the right arguments" do
          expect(request_onelogin_token_use_case).to have_received(:execute).with(code: "test_code", redirect_uri: "http://get-energy-performance-data/login/callback")
        end

        it "passes the validation and redirects" do
          expect(last_response.status).to eq(302)
          expect(last_response.location).to include "/test-redirect-path?nocache="
        end

        it "calls the check_one_login_errors method" do
          expect(Helper::Onelogin).to have_received(:check_one_login_errors).with(code: "test_code", state: "test_state")
        end

        it "calls the validate_id_token_use_case with the right arguments" do
          expect(validate_id_token_use_case).to have_received(:execute).with(token_response_hash:, nonce: "test_nonce")
        end

        it "calls set_session_value for the email address" do
          expect(Helper::Session).to have_received(:set_session_value).with(anything, :email_address, "test@email.com")
        end

        it "calls the get user id use case" do
          expect(get_user_id_use_case).to have_received(:execute).with(email: "test@email.com", one_login_sub: "urn:fdc:gov.uk:2022:56P4CMsGh_02YOlWpd8PAOI-2sVlB2nsNU7mcLZYhYw=")
        end

        it "sets the user id into the session" do
          expect(Helper::Session).to have_received(:set_session_value).with(anything, :user_id, "e40c46c3-4636-4a8a-abd7-be72e1a525f6")
        end

        it "gets the referer from the session" do
          expect(Helper::Session).to have_received(:get_session_value).with(anything, :referer)
        end

        context "when the referer has query parameters" do
          before do
            get callback_url, { code: "test_code", state: "test_state" }, { "rack.session" => { nonce: "test_nonce", state: "test_state", referer: "filter-properties%3Fproperty_type%3Ddomestic" } }
          end

          it "uses the query parameters in the redirect" do
            expect(last_response.location).to include "/filter-properties?property_type=domestic&nocache="
          end
        end

        context "when the referer is a download with a file query parameter" do
          before do
            get callback_url, { code: "test_code", state: "test_state" }, { "rack.session" => { nonce: "test_nonce", state: "test_state", referer: "download?file=output/323eee63-6c56-4e77-9e36-7699f4cb240.csv" } }
          end

          it "redirects back to the download endpoint with the original file and nocache parameters" do
            expect(last_response.location).to include "/download?file=output/323eee63-6c56-4e77-9e36-7699f4cb240.csv&nocache="
          end
        end

        context "when the referer is download all with a property type query parameter" do
          before do
            get callback_url, { code: "test_code", state: "test_state" }, { "rack.session" => { nonce: "test_nonce", state: "test_state", referer: "download/all?property_type=domestic" } }
          end

          it "redirects back to the download all endpoint with the original query and nocache parameters" do
            expect(last_response.location).to include "/download/all?property_type=domestic&nocache="
          end
        end
      end

      context "when id token is invalid" do
        before do
          allow(validate_id_token_use_case).to receive(:execute).and_return(false)
          get callback_url, { code: "test_code", state: "test_state" }, { "rack.session" => { nonce: "test_nonce", state: "test_state", referer: "not_empty" } }
        end

        it "raises 500" do
          expect(last_response.status).to eq(500)
        end
      end

      context "when the referer session value is set to 'type-of-properties'" do
        before do
          get callback_url, { code: "test_code", state: "test_state" }, { "rack.session" => { nonce: "test_nonce", state: "test_state", referer: "type-of-properties" } }
        end

        it "redirects to the type of properties page" do
          redirect_uri = URI(last_response.location)
          expect(redirect_uri.path).to eq("/type-of-properties")
          expect(redirect_uri.query).to eq("nocache=1750852800")
        end
      end

      context "when the referer session value is set to 'api/my-account'" do
        before do
          get callback_url, { code: "test_code", state: "test_state" }, { "rack.session" => { nonce: "test_nonce", state: "test_state", referer: "api/my-account" } }
        end

        it "redirects to the my account page" do
          redirect_uri = URI(last_response.location)
          expect(redirect_uri.path).to eq("/api/my-account")
          expect(redirect_uri.query).to eq("nocache=1750852800")
        end
      end

      context "when the referer session value is set to 'opt-out'" do
        before do
          get callback_url, { code: "test_code", state: "test_state" }, { "rack.session" => { nonce: "test_nonce", state: "test_state", referer: "opt-out" } }
        end

        it "redirects to the opt-out/name page" do
          redirect_uri = URI(last_response.location)
          expect(redirect_uri.path).to eq("/opt-out/name")
          expect(redirect_uri.query).to eq("nocache=1750852800")
        end

        it "does not generate a user id from dynamo db" do
          expect(get_user_id_use_case).not_to have_received(:execute)
        end
      end

      context "when the referer session value is set to 'guidance/energy-certificate-data-apis'" do
        before do
          get callback_url, { code: "test_code", state: "test_state" }, { "rack.session" => { nonce: "test_nonce", state: "test_state", referer: "guidance/energy-certificate-data-apis" } }
        end

        it "redirects to the guidance/energy-certificate-data-apis page" do
          redirect_uri = URI(last_response.location)
          expect(redirect_uri.path).to eq("/guidance/energy-certificate-data-apis")
          expect(redirect_uri.query).to eq("nocache=1750852800")
        end
      end

      context "when the referer session data is missing" do
        before do
          get callback_url, { code: "test_code", state: "test_state" }, { "rack.session" => { nonce: "test_nonce", state: "test_state" } }
        end

        it "redirects to the home page" do
          redirect_uri = URI(last_response.location)
          expect(redirect_uri.path).to eq("/")
        end
      end
    end

    context "when request raises StateMismatch error" do
      context "when the referer session value is set to 'opt-out/name'" do
        before do
          get callback_url, { code: "test_code", state: "test_state" }, { "rack.session" => { nonce: "test_nonce", state: "different_test_state", referer: "opt-out" } }
        end

        it "redirects to the one login page with the correct referer" do
          expect(last_response.status).to eq(302)
          expect(last_response.headers["Location"]).to eq("http://get-energy-performance-data/login?referer=opt-out")
        end
      end

      context "when the referer session value is set to 'api/my-account'" do
        before do
          get callback_url, { code: "test_code", state: "test_state" }, { "rack.session" => { nonce: "test_nonce", state: "different_test_state", referer: "api%2Fmy-account" } }
        end

        it "redirects to the OneLogin login page with the correct referer" do
          expect(last_response.status).to eq(302)
          expect(last_response.headers["Location"]).to eq("http://get-energy-performance-data/login/authorize?referer=api%2Fmy-account")
        end
      end

      context "when the referer session value is set to 'type-of-properties'" do
        before do
          get callback_url, { code: "test_code", state: "test_state" }, { "rack.session" => { nonce: "test_nonce", state: "different_test_state", referer: "type-of-properties%3Fproperty_type%3Ddomestic" } }
        end

        it "redirects to the OneLogin login page with the correct referer including parameters" do
          expect(last_response.status).to eq(302)
          expect(last_response.headers["Location"]).to eq("http://get-energy-performance-data/login/authorize?referer=type-of-properties%3Fproperty_type%3Ddomestic")
        end
      end

      context "when the referer session value is set to a 'download'" do
        before do
          get callback_url, { code: "test_code", state: "test_state" }, { "rack.session" => { nonce: "test_nonce", state: "different_test_state", referer: "download%3Ffile%3Doutput%2F323eee63-6c56-4e77-9e36-7699f4cb240.csv" } }
        end

        it "redirects to the OneLogin login page with the correct referer" do
          expect(last_response.status).to eq(302)
          expect(last_response.headers["Location"]).to eq("http://get-energy-performance-data/login/authorize?referer=download%3Ffile%3Doutput%2F323eee63-6c56-4e77-9e36-7699f4cb240.csv")
        end
      end

      context "when the referer session value is set to 'guidance/energy-certificate-data-apis'" do
        before do
          get callback_url, { code: "test_code", state: "test_state" }, { "rack.session" => { nonce: "test_nonce", state: "different_test_state", referer: "guidance%2Fenergy-certificate-data-apis" } }
        end

        it "redirects to the OneLogin login page with the correct referer" do
          expect(last_response.status).to eq(302)
          expect(last_response.headers["Location"]).to eq("http://get-energy-performance-data/login/authorize?referer=guidance%2Fenergy-certificate-data-apis")
        end
      end
    end

    context "when user email fails to be encrypted and request raises KmsEncryptionError" do
      before do
        allow(Helper::Onelogin).to receive(:set_user_one_login_info).and_raise(Errors::KmsEncryptionError, "Failed to encrypt the email")
        get callback_url, { code: "test_code", state: "test_state" }, { "rack.session" => { nonce: "test_nonce", state: "test_state", referer: "test-redirect-path" } }
      end

      it "raises 500 error" do
        expect(last_response.status).to eq(500)
      end
    end
  end
end

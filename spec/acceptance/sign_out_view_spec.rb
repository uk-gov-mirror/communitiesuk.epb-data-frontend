describe "Acceptance::SignOut", type: :feature do
  include RSpecFrontendServiceMixin

  let(:local_host) do
    "http://get-energy-performance-data"
  end

  let(:response) { get "#{local_host}/signed-out" }

  it "returns status 200" do
    expect(response.status).to eq(200)
  end

  it "has correct header" do
    expect(response.body).to have_selector("h1", text: "You have been signed out")
  end

  it "displays the title the same as the main header value" do
    expect(response.body).to have_title "You have been signed out – GOV.UK"
  end

  it "the one login link is included" do
    expect(response.body).to have_link("GOV.UK One Login", href: "/login/authorize?referer=api/my-account")
  end

  it "includes the link text" do
    expect(response.body).to have_selector("p", text: "To go back, sign in to our service using")
  end

  it "the page does not include the sign out link" do
    expect(response.body).not_to have_selector("button", text: "Sign out")
  end

  describe "get .get-energy-certificate-data.epb-frontend/sign-out" do
    let(:id_token) do
      "eyJhbGciOiJSUzI1NiIsImtpZCI6IjFlOWdkazcifQ.ewogImlzcyI6ICJodHRwOi8vc2VydmVyLmV4YW1wbGUuY29tIiwKICJzdWIiOiAiMjQ4Mjg"
    end

    before do
      allow(Helper::Session).to receive(:get_session_value).and_return(id_token)
      allow(Helper::Session).to receive(:clear_session)
      get "#{local_host}/sign-out"
    end

    context "when the request is received" do
      it "returns status 302" do
        expect(last_response.status).to eq(302)
      end

      it "redirects to the OneLogin authorization URL with the correct host and path" do
        uri = URI(last_response.headers["Location"])
        expect(uri.host).to eq(ENV["ONELOGIN_HOST_URL"].gsub("https://", ""))
        expect(uri.path).to eq("/logout")
      end

      it "redirects to the OneLogin authorization URL with the correct query parameters" do
        uri = URI(last_response.headers["Location"])
        query_params = Rack::Utils.parse_query(uri.query)
        expect(query_params["post_logout_redirect_uri"]).to eq("#{local_host}/signed-out")
        expect(query_params["id_token_hint"]).to eq(id_token)
      end

      it "clear the session" do
        expect(Helper::Session).to have_received(:clear_session)
      end
    end
  end
end

describe "Acceptance::TypeOfProperties", type: :feature do
  include RSpecFrontendServiceMixin
  let(:local_host) do
    "http://get-energy-performance-data/type-of-properties"
  end

  describe "post .get-energy-certificate-data.epb-frontend/type-of-properties" do
    let(:response) { post local_host }

    context "when the user is not authenticated" do
      before do
        allow(Helper::Session).to receive(:is_user_authenticated?).and_raise(Errors::AuthenticationError, "Session is not available")
      end

      it "redirects to /login/authorize using status 303" do
        expect(response.status).to eq(303)
        expect(response.location).to include "/login/authorize?referer=type-of-properties"
      end
    end
  end

  describe "get .get-energy-certificate-data.epb-frontend/type-of-properties" do
    let(:response) { get local_host }

    before do
      allow(Helper::Session).to receive(:is_user_authenticated?).and_return(true)
    end

    context "when the type of properties page is rendered" do
      it "returns status 200" do
        expect(response.status).to eq(200)
      end

      it "shows a back link" do
        expect(response.body).to have_link "Back", href: "/data-access-options"
      end

      it "has the correct form header" do
        expect(response.body).to have_css("h1", text: "What type of certificates do you want data on?")
      end

      it "displays the title the same as the main header value" do
        expect(response.body).to have_title "What type of certificates do you want data on? – GOV.UK"
      end

      it "has the correct content for epc radio button" do
        expect(response.body).to have_css("label.govuk-label", text: "Energy Performance Certificates")
        expect(response.body).to have_css("div.govuk-hint", id: "domestic-item-hint", text: "For domestic properties such as houses or flats")
      end

      it "has the correct content for non-domestic radio button" do
        expect(response.body).to have_css("label.govuk-label", text: "Non-domestic Energy Performance Certificates")
        expect(response.body).to have_css("div.govuk-hint", id: "non-domestic-hint", text: "For non-domestic properties such as commercial or industrial buildings")
      end

      it "has the correct content for dec radio button" do
        expect(response.body).to have_css("label.govuk-label", text: "Display Energy Certificates")
        expect(response.body).to have_css("div.govuk-hint", id: "display-hint", text: "For public buildings such as schools or hospitals")
      end

      it "has the correct content for dropdown" do
        expect(response.body).to have_css("span.govuk-details__summary-text", text: "What buildings have a Display Energy Certificate?")
        expect(response.body).to have_content("Buildings that are occupied by a public authority, are frequently visited by the public and have a floor area above 250m² must have a Display Energy Certificate.")
        expect(response.body).to have_content("Buildings with a Display Energy Certificate may also have a Non-domestic Energy Performance Certificate.")
      end

      it "has a continue button" do
        expect(response.body).to have_button("Continue")
      end
    end

    context "when submitting with a property type" do
      let(:domestic_response) do
        post "http://get-energy-performance-data/type-of-properties", { property_type: "domestic" }
      end

      let(:non_domestic_response) do
        post "http://get-energy-performance-data/type-of-properties", { property_type: "non-domestic" }
      end

      it "routes to the domestic page with the domestic property_type param" do
        expect(domestic_response.status).to eq(302)
        expect(domestic_response.location).to include("/filter-properties?property_type=domestic")
      end

      it "routes to the non-domestic page with the non-domestic property_type param" do
        expect(non_domestic_response).to be_redirect
        expect(non_domestic_response.location).to include("/filter-properties?property_type=non-domestic")
      end
    end

    context "when submitting without deciding a property type" do
      let(:response) do
        post "http://get-energy-performance-data/type-of-properties"
      end

      it "contains the required GDS error summary" do
        expect(response.body).to have_css("div.govuk-error-summary h2.govuk-error-summary__title", text: "There is a problem")
        expect(response.body).to have_css("div.govuk-error-summary__body ul.govuk-list li:first a", text: "Select a type of certificate")
        expect(response.body).to have_link("Select a type of certificate", href: "#property-type-error")
      end
    end

    context "when the user is authenticated" do
      before { allow(Helper::Session).to receive(:is_user_authenticated?).and_return(true) }

      it "allows access to the type of properties page" do
        expect(response.body).to include("What type of certificates do you want data on?")
      end
    end

    context "when the user is not authenticated" do
      before do
        allow(Helper::Session).to receive(:is_user_authenticated?).and_raise(Errors::AuthenticationError, "User is not authenticated")
      end

      it "redirects to the OneLogin login page" do
        expect(response).to be_redirect
        expect(response.location).to eq("http://get-energy-performance-data/login/authorize?referer=type-of-properties")
      end
    end
  end
end

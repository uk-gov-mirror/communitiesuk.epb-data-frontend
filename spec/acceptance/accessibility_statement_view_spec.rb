describe "Acceptance::AccessibilityStatement", type: :feature do
  include RSpecFrontendServiceMixin

  describe "get .get-energy-certificate-data.epb-frontend/accessibility-statement" do
    context "when accessibility statement page rendered" do
      let(:response) do
        get "http://get-energy-performance-data/accessibility-statement"
      end

      it "displays the accessibility statement main page headers" do
        expect(response.body).to have_css("h1.govuk-heading-xl", text: "Accessibility statement")
        expect(response.body).to have_css("h2.govuk-heading-l", text: "Feedback and contact information")
        expect(response.body).to have_css("h2.govuk-heading-l", text: "Reporting accessibility problems with this website")
        expect(response.body).to have_css("h2.govuk-heading-l", text: "Enforcement procedure")
        expect(response.body).to have_css("h2.govuk-heading-l", text: "Technical information about this website’s accessibility")
        expect(response.body).to have_css("h2.govuk-heading-l", text: "What we’re doing to improve accessibility")
        expect(response.body).to have_css("h2.govuk-heading-l", text: "Preparation of this accessibility statement")
      end

      it "displays the title the same as the main header value" do
        expect(response.body).to have_title "Accessibility statement – GOV.UK"
      end

      it "displays the accessibility statement contents" do
        expect(response.body).to include(
          "The Ministry of Housing, Communities and Local Government is committed to making its website accessible",
        )
      end
    end
  end
end

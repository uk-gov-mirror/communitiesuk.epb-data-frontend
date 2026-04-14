# frozen_string_literal: true

describe "Acceptance::Layout", type: :feature do
  include RSpecFrontendServiceMixin

  let(:local_host) do
    "http://get-energy-performance-data"
  end

  describe "get .get-energy-certificate-data.epb-frontend" do
    context "when the home page is rendered" do
      let(:response) { get local_host }

      it "tab value is the same as the main header value" do
        expect(response.body).to include(
          "<title>Get energy performance of buildings data – GOV.UK</title>",
        )
      end

      it "includes the gov header" do
        expect(response.body).to have_link "Get energy performance of buildings data"
      end

      it "does allows indexing but not following by crawlers" do
        expect(response.body).to include('<meta name="robots" content="nofollow">')
      end

      it "does not display the sign out button" do
        expect(response.body).not_to have_link("My account", href: "/api/my-account")
      end

      it "has a link in the footer for the accessibility statement" do
        expect(response.body).to have_css("footer ul.govuk-footer__inline-list li:nth-child(1) a", text: "Accessibility")
        expect(response.body).to have_link("Accessibility", href: "/accessibility-statement")
      end

      it "has a link in the footer for the cookies page" do
        expect(response.body).to have_css("footer ul.govuk-footer__inline-list li:nth-child(2) a", text: "Cookies")
        expect(response.body).to have_link("Cookies", href: "/cookies")
      end

      it "includes the cookie banner" do
        expect(response.body).to include("govuk-cookie-banner")
      end

      context "when in integration" do
        curr_env = ENV["STAGE"]

        before { ENV["STAGE"] = "integration" }

        after { ENV["STAGE"] = curr_env }

        it "includes the test site banner" do
          expect(response.body).to include("govuk-phase-banner")
          expect(response.body).to include("Integration")
          expect(response.body).not_to include("Beta")
        end
      end

      context "when in staging" do
        curr_env = ENV["STAGE"]

        before { ENV["STAGE"] = "staging" }

        after { ENV["STAGE"] = curr_env }

        it "includes the test site banner" do
          expect(response.body).to include("govuk-phase-banner")
          expect(response.body).to include("Staging")
          expect(response.body).not_to include("Beta")
        end
      end

      context "when in production" do
        curr_env = ENV["STAGE"]

        before { ENV["STAGE"] = "production" }

        after { ENV["STAGE"] = curr_env }

        it "includes the feedback banner" do
          expect(response.body).to include("govuk-phase-banner")
          expect(response.body).to include("Beta")
        end
      end

      context "when a user is signed in" do
        before do
          allow(Helper::Session).to receive(:is_logged_in?).and_return(true)
        end

        it "displays the my account button" do
          expect(response.body).to have_link("My account", href: "/api/my-account")
        end
      end

      context "when a user is not signed in" do
        before do
          allow(Helper::Session).to receive(:is_logged_in?).and_return(false)
        end

        it "does not display the my account button" do
          expect(response.body).not_to have_link("My account", href: "/api/my-account")
        end
      end

      context "when on the opt-out journey" do
        let(:response) { get "#{local_host}/opt-out" }

        it "does not show 'gov header' banner text" do
          expect(response.body).not_to have_link "Get energy performance of buildings data"
        end

        it "does not allow indexing or following by crawlers" do
          expect(response.body).to include('<meta name="robots" content="noindex, nofollow">')
        end
      end
    end
  end
end

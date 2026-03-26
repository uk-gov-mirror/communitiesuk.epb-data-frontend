require_relative "../../shared_examples/shared_opt_out_authentication"
describe "Acceptance::OptOutCertificateDetails", type: :feature do
  include RSpecFrontendServiceMixin

  let(:base_url) { "http://get-energy-performance-data" }

  describe "get .get-energy-certificate-data.epb-frontend/opt-out/certificate-details" do
    let(:response) { get "#{base_url}/opt-out/certificate-details" }

    context "when the user is authenticated" do
      before do
        allow(Helper::Session).to receive_messages(
          is_user_authenticated?: true,
          get_email_from_session: "test@email.com",
        )
        allow(Helper::Session).to receive(:get_session_value).with(anything, anything).and_call_original
        allow(Helper::Session).to receive(:get_session_value).with(anything, :opt_out_owner).and_return("yes")
        allow(Helper::Session).to receive(:get_session_value).with(anything, :opt_out_occupant).and_return(nil)
        allow(Helper::Session).to receive(:get_session_value).with(anything, :opt_out_name).and_return("Testy McTest")
      end

      it "returns status 200" do
        expect(response.status).to eq(200)
      end

      it "displays the title as expected" do
        expect(response.body).to have_css("h1", text: "Which property would you like to opt out?")
      end

      it "has the label and input for the name" do
        expect(response.body).to have_css("label#certificate-number-label", text: "Certificate number")
        expect(response.body).to have_css("input#certificate-number[type='text']", count: 1)
      end

      it "has the correct Continue button" do
        expect(response.body).to have_css("button[type='submit']", text: "Continue")
      end

      it_behaves_like "when checking an authorisation for opt-out restricted endpoints", end_point: "certificate-details"

      context "when the user skipped over the eligibility questions" do
        before do
          allow(Helper::Session).to receive(:get_session_value).with(anything, :opt_out_owner).and_return(nil)
          allow(Helper::Session).to receive(:get_session_value).with(anything, :opt_out_occupant).and_return(nil)
          allow(Helper::Session).to receive(:get_session_value).with(anything, :opt_out_name).and_return("Testy McTest")
        end

        it "returns status 302" do
          expect(response.status).to eq(302)
        end

        it "redirects to the start page" do
          expect(response.location).to include("/opt-out")
        end
      end

      context "when the user was not eligible" do
        before do
          allow(Helper::Session).to receive(:get_session_value).with(anything, :opt_out_owner).and_return("no")
          allow(Helper::Session).to receive(:get_session_value).with(anything, :opt_out_occupant).and_return("no")
          allow(Helper::Session).to receive(:get_session_value).with(anything, :opt_out_name).and_return("Testy McTest")
        end

        it "returns status 302" do
          expect(response.status).to eq(302)
        end

        it "redirects to ineligible page" do
          expect(response.location).to include("/opt-out/ineligible")
        end
      end

      context "when the user skipped over the name step" do
        before do
          allow(Helper::Session).to receive(:get_session_value).with(anything, :opt_out_owner).and_return("no")
          allow(Helper::Session).to receive(:get_session_value).with(anything, :opt_out_occupant).and_return("yes")
          allow(Helper::Session).to receive(:get_session_value).with(anything, :opt_out_name).and_return(nil)
        end

        it "returns status 302" do
          expect(response.status).to eq(302)
        end

        it "redirects to ineligible page" do
          expect(response.location).to include("/opt-out/name")
        end
      end

      context "when there is already a session" do
        before do
          allow(Helper::Session).to receive(:get_session_value).with(anything, :opt_out_certificate_number).and_return("1234-4567-1234-4567-1234")
          allow(Helper::Session).to receive(:get_session_value).with(anything, :opt_out_address_line1).and_return("123 Fake Street")
          allow(Helper::Session).to receive(:get_session_value).with(anything, :opt_out_address_line2).and_return("")
          allow(Helper::Session).to receive(:get_session_value).with(anything, :opt_out_address_town).and_return("London")
          allow(Helper::Session).to receive(:get_session_value).with(anything, :opt_out_address_postcode).and_return("TE57 1NG")
        end

        it "is pre filled with the correct certificate number value" do
          expect(response.body).to have_css("div.govuk-form-group input#certificate-number[value='1234-4567-1234-4567-1234']")
        end

        it "is pre filled with the correct address line 1 value" do
          expect(response.body).to have_css("div.govuk-form-group input#address-line1[value='123 Fake Street']")
        end

        it "is pre filled with the correct address line 2 value" do
          expect(response.body).to have_css("div.govuk-form-group input#address-line-2[value='']")
        end

        it "is pre filled with the correct town value" do
          expect(response.body).to have_css("div.govuk-form-group input#address-town[value='London']")
        end

        it "is pre filled with the correct postcode value" do
          expect(response.body).to have_css("div.govuk-form-group input#address-postcode[value='TE57 1NG']")
        end
      end
    end
  end

  describe "post .get-energy-certificate-data.epb-frontend/opt-out/certificate-details" do
    before do
      allow(Helper::Session).to receive(:get_session_value).with(anything, anything).and_call_original
      allow(Helper::Session).to receive(:set_session_value)
    end

    context "when the user is authenticated" do
      before do
        allow(Helper::Session).to receive_messages(
          is_user_authenticated?: true,
          get_email_from_session: "test@email.com",
        )
      end

      context "when all required inputs are provided" do
        let(:response) { post "#{base_url}/opt-out/certificate-details", { certificate_number: "0000-0000-0000-0000-0000", address_line1: "5 Bob Street", address_line2: "Test Grove", address_town: "Testerton", address_postcode: "TE57 1NG" } }

        it "returns status 302" do
          expect(response.status).to eq(302)
        end

        it "redirects to the certificate-details page" do
          expect(response.location).to include("/opt-out/check-your-answers")
        end

        it "saves the certificate number in the session" do
          response
          expect(Helper::Session).to have_received(:set_session_value).with(anything, :opt_out_certificate_number, "0000-0000-0000-0000-0000")
        end

        it "saves the address line 1 in the session" do
          response
          expect(Helper::Session).to have_received(:set_session_value).with(anything, :opt_out_address_line1, "5 Bob Street")
        end

        it "saves the address line 2 in the session" do
          response
          expect(Helper::Session).to have_received(:set_session_value).with(anything, :opt_out_address_line2, "Test Grove")
        end

        it "saves the town in the session" do
          response
          expect(Helper::Session).to have_received(:set_session_value).with(anything, :opt_out_address_town, "Testerton")
        end

        it "saves the postcode in the session" do
          response
          expect(Helper::Session).to have_received(:set_session_value).with(anything, :opt_out_address_postcode, "TE57 1NG")
        end
      end

      context "when the input is empty" do
        let(:response) { post "#{base_url}/opt-out/certificate-details", { certificate_number: " ", address_line1: " ", address_line2: " ", address_town: " ", address_postcode: " " } }

        it "returns status 200" do
          expect(response.status).to eq(200)
        end

        it "displays the error summary" do
          expect(response.body).to have_css("div.govuk-error-summary")
        end

        it "display the certificate number error" do
          expect(response.body).to have_css("p#certificate-number-error", text: /Enter a valid certificate number/)
        end

        it "display the address line 1 error" do
          expect(response.body).to have_css("p#address-line1-error", text: /Enter the first line of your address/)
        end

        it "display the postcode error" do
          expect(response.body).to have_css("p#address-postcode-error", text: /Enter a valid postcode/)
        end
      end

      context "when the certificate number is not valid" do
        let(:response) { post "#{base_url}/opt-out/certificate-details", { certificate_number: "TEST ERROR", address_line1: "5 Bob Street", address_line2: "Test Grove", address_town: "Testerton", address_postcode: "TE57 1NG" } }

        it "returns status 200" do
          expect(response.status).to eq(200)
        end

        it "displays the error summary" do
          expect(response.body).to have_css("div.govuk-error-summary")
        end

        it "display the selection error" do
          expect(response.body).to have_css("p#certificate-number-error", text: /Enter a valid certificate number/)
        end
      end

      context "when the postcode is not valid" do
        let(:response) { post "#{base_url}/opt-out/certificate-details", { certificate_number: "0000-0000-0000-0000-0000", address_line1: "5 Bob Street", address_line2: "Test Grove", address_town: "Testerton", address_postcode: "BOB" } }

        it "returns status 200" do
          expect(response.status).to eq(200)
        end

        it "displays the error summary" do
          expect(response.body).to have_css("div.govuk-error-summary")
        end

        it "display the selection error" do
          expect(response.body).to have_css("p#address-postcode-error", text: /Enter a valid postcode/)
        end
      end

      context "when address line 1 is longer than 255 characters" do
        let(:response) { post "#{base_url}/opt-out/certificate-details", { certificate_number: "0000-0000-0000-0000-0000", address_line1: "256chars" * 32, address_line2: "Test Grove", address_town: "Testerton", address_postcode: "TE57 1NG" } }

        it "returns status 200" do
          expect(response.status).to eq(200)
        end

        it "displays the error summary" do
          expect(response.body).to have_css("div.govuk-error-summary")
        end

        it "display the selection error" do
          expect(response.body).to have_css("p#address-line1-error", text: /Address line 1 must be 255 characters or less/)
        end
      end

      context "when address line 2 is longer than 255 characters" do
        let(:response) { post "#{base_url}/opt-out/certificate-details", { certificate_number: "0000-0000-0000-0000-0000", address_line1: "5 Bob Street", address_line2: "256chars" * 32, address_town: "Testerton", address_postcode: "TE57 1NG" } }

        it "returns status 200" do
          expect(response.status).to eq(200)
        end

        it "displays the error summary" do
          expect(response.body).to have_css("div.govuk-error-summary")
        end

        it "display the selection error" do
          expect(response.body).to have_css("p#address-line2-error", text: /Address line 2 must be 255 characters or less/)
        end
      end

      context "when town or city is longer than 255 characters" do
        let(:response) { post "#{base_url}/opt-out/certificate-details", { certificate_number: "0000-0000-0000-0000-0000", address_line1: "5 Bob Street", address_line2: "Test Grove", address_town: "256chars" * 32, address_postcode: "TE57 1NG" } }

        it "returns status 200" do
          expect(response.status).to eq(200)
        end

        it "displays the error summary" do
          expect(response.body).to have_css("div.govuk-error-summary")
        end

        it "display the selection error" do
          expect(response.body).to have_css("p#address-town-error", text: /Town or city must be 255 characters or less/)
        end
      end

      context "when the text fields have tags present" do
        let(:response) { post "#{base_url}/opt-out/certificate-details", { certificate_number: "0000-0000-0000-0000-0000", address_line1: "<img src=x onerror=alert(1)1 Some Street", address_line2: "<h1>Heading</h1>Summer Grove", address_town: "<script>console.log('hello')</script>Large Town", address_postcode: "TE57 1NG" } }

        it "returns status 200" do
          expect(response.status).to eq(200)
        end

        it "displays the error summary" do
          expect(response.body).to have_css("div.govuk-error-summary")
        end

        it "displays the errors" do
          expect(response.body).to have_css("p#address-line1-error", text: /Invalid text/)
          expect(response.body).to have_css("p#address-line2-error", text: /Invalid text/)
          expect(response.body).to have_css("p#address-town-error", text: /Invalid text/)
        end
      end
    end
  end
end

require_relative "../../shared_examples/shared_opt_out_authentication"
describe "Acceptance::OptOutOwner", type: :feature do
  include RSpecFrontendServiceMixin

  let(:base_url) { "http://get-energy-performance-data" }

  describe "get .get-energy-certificate-data.epb-frontend/opt-out/name" do
    let(:response) { get "#{base_url}/opt-out/name" }

    context "when the user is authenticated" do
      before do
        allow(Helper::Session).to receive_messages(
          is_user_authenticated?: true,
          get_email_from_session: "test@email.com",
        )
        allow(Helper::Session).to receive(:get_session_value).with(anything, anything).and_call_original
        allow(Helper::Session).to receive(:get_session_value).with(anything, :opt_out_owner).and_return("yes")
      end

      it "returns status 200" do
        expect(response.status).to eq(200)
      end

      it "contains the correct h1 header" do
        expect(response.body).to have_selector("h1", text: "What is your full name?")
      end

      it "has the label and input for the name" do
        expect(response.body).to have_css("label#label_name", text: "Full name")
        expect(response.body).to have_css("input#name[type='text']", count: 1)
      end

      it "has the correct Continue button" do
        expect(response.body).to have_css("button[type='submit']", text: "Continue")
      end

      context "when there is already a session" do
        before do
          allow(Helper::Session).to receive(:get_session_value).with(anything, :opt_out_name).and_return("Joe Smith")
        end

        it "is pre filled with the correct name value" do
          expect(response.body).to have_css("div.govuk-form-group input#name[value='Joe Smith']")
        end
      end

      context "when the session is not valid" do
        before do
          allow(Helper::Session).to receive_messages(
            is_user_authenticated?: true,
            get_email_from_session: "test@email.com",
          )
          allow(Helper::Session).to receive(:get_session_value).with(anything, anything).and_call_original
          allow(Helper::Session).to receive(:get_session_value).with(anything, :opt_out_owner).and_return(nil)
          allow(Helper::Session).to receive(:get_session_value).with(anything, :opt_out_occupant).and_return(nil)
        end

        it "redirects to the /opt-out page" do
          expect(response.location).to eq("#{base_url}/opt-out")
        end
      end
    end

    it_behaves_like "when checking an authorisation for opt-out restricted endpoints", end_point: "name"
  end

  describe "post .get-energy-certificate-data.epb-frontend/opt-out/name" do
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

      context "when there is a name in the input" do
        let(:response) { post "#{base_url}/opt-out/name", { name: "Testy McTest" } }

        it "returns status 302" do
          expect(response.status).to eq(302)
        end

        it "redirects to the certificate-details page" do
          expect(response.location).to include("/opt-out/certificate-details")
        end

        it "has the session value" do
          response
          expect(Helper::Session).to have_received(:set_session_value).with(anything, :opt_out_name, "Testy McTest")
        end
      end

      context "when the input is empty" do
        let(:response) { post "#{base_url}/opt-out/name", { name: " " } }

        it "returns status 200" do
          expect(response.status).to eq(200)
        end

        it "displays the error summary" do
          expect(response.body).to have_css("div.govuk-error-summary")
        end

        it "display the selection error" do
          expect(response.body).to have_css("p#name-error", text: /Enter your full name/)
        end
      end

      context "when the input is longer than 255 characters empty" do
        let(:response) { post "#{base_url}/opt-out/name", { name: "256chars" * 32 } }

        it "returns status 200" do
          expect(response.status).to eq(200)
        end

        it "displays the error summary" do
          expect(response.body).to have_css("div.govuk-error-summary")
        end

        it "display the selection error" do
          expect(response.body).to have_css("p#name-error", text: /Full name must be 255 characters or less/)
        end
      end

      context "when the input includes html tags" do
        let(:response) { post "#{base_url}/opt-out/name", { name: "<h1>Testy McTest</h1>" } }

        it "returns status 200" do
          expect(response.status).to eq(200)
        end

        it "displays the error summary" do
          expect(response.body).to have_css("div.govuk-error-summary")
        end

        it "displays the invalid text error" do
          expect(response.body).to have_css("p#name-error", text: /Invalid text/)
        end
      end

      context "when the input includes incomplete tags" do
        let(:response) { post "#{base_url}/opt-out/name", { name: "<img src=http://cataas.com/cat" } }

        it "returns status 200" do
          expect(response.status).to eq(200)
        end

        it "displays the error summary" do
          expect(response.body).to have_css("div.govuk-error-summary")
        end

        it "displays the invalid text error" do
          expect(response.body).to have_css("p#name-error", text: /Invalid text/)
        end
      end
    end
  end
end

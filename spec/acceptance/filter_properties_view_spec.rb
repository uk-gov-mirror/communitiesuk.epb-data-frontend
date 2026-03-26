describe "Acceptance::FilterProperties", type: :feature do
  include RSpecFrontendServiceMixin

  let(:local_host) do
    "http://get-energy-performance-data"
  end

  let(:request_url) do
    "#{local_host}/filter-properties"
  end

  let(:response) { get "#{request_url}?property_type=domestic" }

  let(:valid_response) { post "#{request_url}?property_type=domestic&#{valid_dates}&#{valid_eff_rating}" }

  let(:valid_dates) do
    "from-year=2023&from-month=January&to-year=2025&to-month=February"
  end
  let(:invalid_dates) do
    "from-year=2024&from-month=February&to-year=2023&to-month=December"
  end
  let(:valid_eff_rating) do
    "ratings[]=A&ratings[]=B"
  end
  let(:valid_postcode) do
    "postcode=SW1A%201AA"
  end

  let(:get_download_size_use_case) do
    instance_double(UseCase::GetDownloadSize)
  end

  let(:send_sns_use_case) do
    instance_double(UseCase::SendDownloadRequest)
  end

  let(:get_file_size_use_case) do
    instance_double(UseCase::GetFileSize)
  end

  let(:app) do
    fake_container = instance_double(Container)
    allow(fake_container).to receive(:get_object).with(:get_download_size_use_case).and_return(get_download_size_use_case)
    allow(fake_container).to receive(:get_object).with(:send_download_request_use_case).and_return(send_sns_use_case)
    allow(fake_container).to receive(:get_object).with(:get_file_size_use_case).and_return(get_file_size_use_case)

    Rack::Builder.new do
      use Rack::Session::Cookie, secret: "test" * 16
      run Controller::FilterPropertiesController.new(container: fake_container)
    end
  end

  around do |example|
    original_stage = ENV["STAGE"]
    ENV["STAGE"] = "mock"
    example.run
    ENV["STAGE"] = original_stage
  end

  describe "post .get-energy-certificate-data.epb-frontend/filter-properties" do
    let(:response) { post "#{request_url}?property_type=domestic" }

    context "when the user is not authenticated" do
      before do
        allow(Helper::Session).to receive(:is_user_authenticated?).and_raise(Errors::AuthenticationError, "Session is not available")
      end

      it "redirects to /login/authorize using status 303" do
        expect(response.status).to eq(303)
        expect(response.location).to include "/login/authorize?referer=filter-properties"
      end
    end
  end

  describe "get .get-energy-certificate-data.epb-frontend/filter-properties" do
    before do
      allow(ViewModels::FilterProperties).to receive(:get_full_load_file_size).and_return("3.5 GB")
      allow(Helper::Session).to receive_messages(is_user_authenticated?: true, get_email_from_session: "test@email.com")
    end

    context "when the page is rendered" do
      before do
        Timecop.freeze(Time.utc(2025, 4, 1))
      end

      after do
        Timecop.return
      end

      it "returns status 200" do
        expect(response.status).to eq(200)
      end

      it "shows a back link" do
        expect(response.body).to have_link "Back", href: "/type-of-properties"
      end

      it "shows the correct header for domestic" do
        expect(response.body).to have_selector("h1", text: "Energy Performance Certificates")
      end

      it "displays the title the same as the main header value" do
        expect(response.body).to have_title "Energy Performance Certificates – GOV.UK"
      end

      it "does not show the efficiency rating filter for non-domestic and public properties" do
        property_types = %w[non-domestic dec]

        property_types.each do |property_type|
          response = get "#{request_url}?property_type=#{property_type}"
          expect(response.body).not_to have_css("#eff-rating-section.govuk-accordion__section")
        end
      end

      it "shows the efficiency rating filter for domestic properties" do
        expect(response.body).to have_css("#eff-rating-section.govuk-accordion__section")
      end

      it "selects the correct default year and month in the select with id='from-year'" do
        expect(response.body).to have_css("select#from-year option[selected]", text: "2012")
        expect(response.body).to have_css("select#from-month option[selected]", text: "January")
      end

      it "selects the correct default year and month in the select with id='to-year'" do
        expect(response.body).to have_css("select#to-year option[selected]", text: "2025")
        expect(response.body).to have_css("select#to-month option[selected]", text: "March")
      end

      it "shows all efficiency ratings selected by default for domestic properties" do
        response = get "#{request_url}?property_type=domestic"
        expect(response.body).to have_css("input#ratings-A[value=A][checked]")
        expect(response.body).to have_css("input#ratings-B[value=B][checked]")
        expect(response.body).to have_css("input#ratings-C[value=C][checked]")
        expect(response.body).to have_css("input#ratings-D[value=D][checked]")
        expect(response.body).to have_css("input#ratings-E[value=E][checked]")
        expect(response.body).to have_css("input#ratings-F[value=F][checked]")
        expect(response.body).to have_css("input#ratings-G[value=G][checked]")
      end

      it "shows a select of councils" do
        expect(response.body).to have_css(".govuk-select#local-authority")
      end

      it "shows a select of parliamentary constituencies" do
        expect(response.body).to have_css(".govuk-select#parliamentary-constituency")
      end

      it "shows information about the download" do
        expect(response.body).to have_css(".govuk-body", text: "The download will begin immediately once requested. The estimated download size is")
        expect(response.body).to have_css(".govuk-body", text: "3.5 GB")
      end

      context "when the user is not authenticated" do
        before { allow(Helper::Session).to receive(:is_user_authenticated?).and_raise(Errors::AuthenticationError, "User is not authenticated") }

        after { allow(Helper::Session).to receive(:is_user_authenticated?).and_return(true) }

        it "redirects to the login page" do
          expect(response.status).to eq(302)
          expect(response.location).to eq("http://get-energy-performance-data/login/authorize?referer=filter-properties")
        end
      end

      context "when invalid property type is provided" do
        before { get "#{request_url}?property_type=invalid-type" }

        it "returns status 404" do
          expect(last_response.status).to eq(404)
        end

        it "shows the error page" do
          expect(last_response.body).to include(
            '<h1 class="govuk-heading-xl">Page not found</h1>',
          )
        end
      end
    end

    context "when all filters are valid and the session data is valid" do
      before do
        allow(get_download_size_use_case).to receive(:execute).and_return(123)
        allow(send_sns_use_case).to receive(:execute)
      end

      context "when an email is found in the session" do
        before do
          allow(Helper::Session).to receive(:get_session_value).and_return("test@email.com")
        end

        it "the request is received and user is redirected to the confirmation page" do
          expect(valid_response.headers["Location"]).to match(/request-received-confirmation/)
        end

        it "sends the session data to the SNS gateway" do
          valid_response
          expect(send_sns_use_case).to have_received(:execute).with(hash_including(email_address: "test@email.com", property_type: "domestic"))
        end
      end

      context "when the session has expired" do
        before do
          allow(Helper::Session).to receive(:get_email_from_session).and_raise(Errors::SessionEmailError)
        end

        it "no error is raised" do
          expect(valid_response.status).not_to eq(500)
        end

        it "the user is redirected back to the one login login page" do
          expect(valid_response.headers["Location"]).to eq("#{local_host}/signed-out")
        end
      end
    end

    context "when filters are applied" do
      context "when the selected dates are valid" do
        before do
          allow(get_download_size_use_case).to receive(:execute).and_return(123)
          allow(send_sns_use_case).to receive(:execute)
        end

        it "redirects to the request-received-confirmation with the right params" do
          expect(valid_response.status).to eq(302)
          expect(valid_response.headers["Location"]).to eq("#{local_host}/request-received-confirmation?property_type=domestic&from-year=2023&from-month=January&to-year=2025&to-month=February&ratings%5B%5D=A&ratings%5B%5D=B&local-authority%5B%5D=Select+all&parliamentary-constituency%5B%5D=Select+all")
        end

        it "does not display an error message" do
          expect(valid_response.body).not_to have_text "govuk-form-group--error"
          expect(valid_response.body).not_to have_text "govuk-error-message"
        end
      end

      context "when the selected dates are invalid" do
        let(:invalid_response) { post "#{request_url}?property_type=domestic&#{invalid_dates}&#{valid_eff_rating}" }

        it "returns status 400" do
          expect(invalid_response.status).to eq(400)
        end

        it "displays an error message" do
          expect(invalid_response.body).to include(
            '<p id="date-error" class="govuk-error-message">',
          )
        end

        it "keeps the selected dates in the form" do
          expect(invalid_response.body).to include('<option value="2023" selected>')
          expect(invalid_response.body).to include('<option value="2024" selected>')
          expect(invalid_response.body).to include('<option value="February" selected>')
          expect(invalid_response.body).to include('<option value="December" selected>')
        end

        it "shows correct required GDS error summary" do
          expect(invalid_response.body).to have_css("div.govuk-error-summary h2.govuk-error-summary__title", text: "There is a problem")
          expect(invalid_response.body).to have_css("div.govuk-error-summary__body ul.govuk-list li:first a", text: "Select a valid date range")
          expect(invalid_response.body).to have_link("Select a valid date range", href: "#date-section")
        end
      end

      context "when selecting default domestic filters" do
        let(:default_dates) { "from-month=January&from-year=2012&to-month=#{(Date.today << 1).strftime('%B')}&to-year=#{Date.today.year}" }
        let(:default_area) { "postcode=&local-authority[]=Select+all&parliamentary-constituency[]=Select+all" }
        let(:default_eff_rating) { "ratings[]=A&ratings[]=B&ratings[]=C&ratings[]=D&ratings[]=E&ratings[]=F&ratings[]=G" }
        let(:default_filters) { "#{default_dates}&#{default_area}&#{default_eff_rating}" }
        let(:valid_response_with_default_filters) { post "#{request_url}?property_type=domestic&#{default_filters}" }

        it "redirects to the /download/all endpoint" do
          expect(valid_response_with_default_filters.status).to eq(302)
          expect(valid_response_with_default_filters.headers["Location"]).to eq("#{local_host}/download/all?property_type=domestic")
        end
      end

      context "when selecting default non-domestic filters" do
        let(:default_dates) { "from-month=January&from-year=2012&to-month=#{(Date.today << 1).strftime('%B')}&to-year=#{Date.today.year}" }
        let(:default_area) { "postcode=&local-authority[]=Select+all&parliamentary-constituency[]=Select+all" }
        let(:default_filters) { "#{default_dates}&#{default_area}" }
        let(:valid_response_with_default_filters) { post "#{request_url}?property_type=non-domestic&#{default_filters}" }

        it "redirects to the /download/all endpoint" do
          expect(valid_response_with_default_filters.status).to eq(302)
          expect(valid_response_with_default_filters.headers["Location"]).to eq("#{local_host}/download/all?property_type=non-domestic")
        end
      end

      context "when selecting multiple councils" do
        let(:multiple_councils) { "local-authority[]=Birmingham&local-authority[]=Adur" }
        let(:valid_response_with_multiple_councils) { post "#{request_url}?property_type=domestic&#{valid_dates}&#{valid_eff_rating}&#{multiple_councils}" }

        before do
          allow(Helper::Session).to receive(:get_email_from_session).and_return("placeholder@email.com")
          allow(get_download_size_use_case).to receive(:execute).and_return(123)
          allow(send_sns_use_case).to receive(:execute)
        end

        it "redirects to the request-received-confirmation with the right params" do
          expect(valid_response_with_multiple_councils.status).to eq(302)
          expect(valid_response_with_multiple_councils.headers["Location"]).to eq("#{local_host}/request-received-confirmation?property_type=domestic&from-year=2023&from-month=January&to-year=2025&to-month=February&ratings%5B%5D=A&ratings%5B%5D=B&local-authority%5B%5D=Birmingham&local-authority%5B%5D=Adur&parliamentary-constituency%5B%5D=Select+all")
        end
      end

      context "when selecting multiple constituencies" do
        let(:multiple_constituencies) { "parliamentary-constituency[]=Ashford&parliamentary-constituency[]=Cardiff" }
        let(:valid_response_with_multiple_constituencies) { post "#{request_url}?property_type=domestic&#{valid_dates}&#{valid_eff_rating}&#{multiple_constituencies}" }

        before do
          allow(Helper::Session).to receive(:get_email_from_session).and_return("placeholder@email.com")
          allow(get_download_size_use_case).to receive(:execute).and_return(123)
          allow(send_sns_use_case).to receive(:execute)
        end

        it "redirects to the request-received-confirmation with the right params" do
          expect(valid_response_with_multiple_constituencies.status).to eq(302)
          expect(valid_response_with_multiple_constituencies.headers["Location"]).to eq("#{local_host}/request-received-confirmation?property_type=domestic&from-year=2023&from-month=January&to-year=2025&to-month=February&ratings%5B%5D=A&ratings%5B%5D=B&parliamentary-constituency%5B%5D=Ashford&parliamentary-constituency%5B%5D=Cardiff&local-authority%5B%5D=Select+all")
        end
      end

      context "when the postcode is valid" do
        let(:valid_response_with_postcode) { post "#{request_url}?property_type=domestic&#{valid_dates}&#{valid_eff_rating}&#{valid_postcode}&area-type=postcode" }

        before do
          allow(Helper::Session).to receive(:get_email_from_session).and_return("placeholder@email.com")
          allow(get_download_size_use_case).to receive(:execute).and_return(123)
          allow(send_sns_use_case).to receive(:execute)
        end

        it "redirects to the request-received-confirmation with the right params" do
          expect(valid_response_with_postcode.status).to eq(302)
          expect(valid_response_with_postcode.headers["Location"]).to eq("#{local_host}/request-received-confirmation?property_type=domestic&from-year=2023&from-month=January&to-year=2025&to-month=February&ratings%5B%5D=A&ratings%5B%5D=B&postcode=SW1A+1AA&area-type=postcode&local-authority%5B%5D=Select+all&parliamentary-constituency%5B%5D=Select+all")
        end

        it "displays an error message" do
          expect(valid_response_with_postcode.body).not_to include(
            '<p id="postcode-error" class="govuk-error-message">',
          )
        end
      end

      context "when the postcode is invalid" do
        let(:invalid_postcodes) do
          [
            "#{request_url}?property_type=domestic&#{valid_dates}&#{valid_eff_rating}&area-type=postcode&postcode=A",
            "#{request_url}?property_type=domestic&#{valid_dates}&#{valid_eff_rating}&area-type=postcode&postcode=ABCD12345",
            "#{request_url}?property_type=domestic&#{valid_dates}&#{valid_eff_rating}&area-type=postcode&postcode=SW1A 1A$",
          ]
        end

        let(:error_messages) do
          [
            "Enter a full UK postcode in the format LS1 4AP",
            "Enter a valid UK postcode in the format LS1 4AP",
            "Enter a valid UK postcode using only letters and numbers in the format LS1 4AP",
          ]
        end

        let(:invalid_responses) do
          invalid_postcodes.map { |invalid_postcode| post invalid_postcode }
        end

        it "returns status 400" do
          invalid_responses.each do |invalid_response|
            expect(invalid_response.status).to eq(400)
          end
        end

        it "displays an error message" do
          invalid_responses.each do |invalid_response|
            expect(invalid_response.body).to include(
              '<p id="postcode-error" class="govuk-error-message">',
            )
            expect(invalid_response.body).to have_css(
              "#conditional-area-type-postcode .govuk-form-group.govuk-form-group--error",
            )
          end
        end

        it "shows correct required GDS error summary" do
          invalid_responses.each_with_index do |invalid_response, index|
            expect(invalid_response.body).to have_css("div.govuk-error-summary h2.govuk-error-summary__title", text: "There is a problem")
            expect(invalid_response.body).to have_css("div.govuk-error-summary__body ul.govuk-list li:first a", text: error_messages[index])
            expect(invalid_response.body).to have_link(error_messages[index], href: "#area-type-section")
          end
        end
      end

      context "when the postcode is selected, but empty" do
        let(:valid_response_with_empty_postcode) { post "#{request_url}?property_type=domestic&#{valid_dates}&#{valid_eff_rating}&postcode=%20%20&area-type=postcode" }

        before do
          allow(Helper::Session).to receive(:get_email_from_session).and_return("placeholder@email.com")
          allow(get_download_size_use_case).to receive(:execute).and_return(123)
          allow(send_sns_use_case).to receive(:execute)
        end

        it "redirects to the request-received-confirmation with the right params" do
          expect(valid_response_with_empty_postcode.status).to eq(302)
          expect(valid_response_with_empty_postcode.headers["Location"]).to eq("#{local_host}/request-received-confirmation?property_type=domestic&from-year=2023&from-month=January&to-year=2025&to-month=February&ratings%5B%5D=A&ratings%5B%5D=B&postcode=&area-type=postcode&local-authority%5B%5D=Select+all&parliamentary-constituency%5B%5D=Select+all")
        end

        it "displays an error message" do
          expect(valid_response_with_empty_postcode.body).not_to include(
            '<p id="postcode-error" class="govuk-error-message">',
          )
        end
      end

      context "when the efficiency rating selection is valid" do
        before do
          allow(Helper::Session).to receive(:get_email_from_session).and_return("placeholder@email.com")
          allow(get_download_size_use_case).to receive(:execute).and_return(123)
          allow(send_sns_use_case).to receive(:execute)
        end

        it "redirects to the request-received-confirmation with the right params" do
          expect(valid_response.status).to eq(302)
          expect(valid_response.headers["Location"]).to eq("#{local_host}/request-received-confirmation?property_type=domestic&from-year=2023&from-month=January&to-year=2025&to-month=February&ratings%5B%5D=A&ratings%5B%5D=B&local-authority%5B%5D=Select+all&parliamentary-constituency%5B%5D=Select+all")
        end

        it "displays an error message" do
          expect(valid_response.body).not_to include(
            '<p id="eff-rating-error" class="govuk-error-message">',
          )
        end
      end

      context "when the efficiency rating selection is invalid" do
        let(:invalid_response) { post "#{request_url}?property_type=domestic&#{valid_dates}" }

        it "returns status 400" do
          expect(invalid_response.status).to eq(400)
        end

        it "keeps the efficiency ratings unchecked when none is selected" do
          expect(invalid_response.body).to have_css("input#ratings-A[value=A]")
          expect(invalid_response.body).to have_css("input#ratings-B[value=B]")
          expect(invalid_response.body).to have_css("input#ratings-C[value=C]")
          expect(invalid_response.body).to have_css("input#ratings-D[value=D]")
          expect(invalid_response.body).to have_css("input#ratings-E[value=E]")
          expect(invalid_response.body).to have_css("input#ratings-F[value=F]")
          expect(invalid_response.body).to have_css("input#ratings-G[value=G]")
        end

        it "displays an error message" do
          expect(invalid_response.body).to include(
            '<p id="eff-rating-error" class="govuk-error-message">',
          )
        end

        it "shows correct required GDS error summary" do
          expect(invalid_response.body).to have_css("div.govuk-error-summary h2.govuk-error-summary__title", text: "There is a problem")
          expect(invalid_response.body).to have_css("div.govuk-error-summary__body ul.govuk-list li:first a", text: "Select at least one rating option")
          expect(invalid_response.body).to have_link("Select at least one rating option", href: "#eff-rating-section")
        end
      end

      context "when no data is found for the selected filters" do
        before do
          allow(get_download_size_use_case).to receive(:execute).and_raise(Errors::FilteredDataNotFound)
        end

        it "returns status 400" do
          expect(valid_response.status).to eq(400)
        end

        it "shows correct required GDS error summary" do
          expect(valid_response.body).to have_css("div.govuk-error-summary h2.govuk-error-summary__title", text: "There is a problem")
          expect(valid_response.body).to have_css("div.govuk-error-summary__body ul.govuk-list li:first a", text: "No certificates were found. Try different filters.")
          expect(valid_response.body).to have_link("No certificates were found. Try different filters.", href: "#filter-properties-header")
        end
      end
    end
  end
end

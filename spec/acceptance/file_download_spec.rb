describe "Acceptance::FileDownload", type: :feature do
  include RSpecFrontendServiceMixin

  before do
    allow(Helper::Session).to receive(:is_user_authenticated?).and_return(true)
  end

  describe "get .get-energy-certificate-data.epb-frontend/download" do
    let(:local_host) do
      "http://get-energy-performance-data/download"
    end

    let(:file_name) do
      "output/323eee63-6c56-4e77-9e36-7699f4cb240.csv"
    end

    let(:response) do
      get "#{local_host}?file=#{file_name}"
    end

    context "when user is authenticated" do
      it "returns the redirect status" do
        expect(response.status).to eq(302)
      end

      it "redirects to file download" do
        expect(response.headers["location"]).to include("https://user-data.s3.us-stubbed-1.amazonaws.com/#{file_name}?X-Amz-Algorithm=AWS4-HMAC")
      end
    end

    context "when user is not authenticated" do
      before { allow(Helper::Session).to receive(:is_user_authenticated?).and_raise(Errors::AuthenticationError, "User is not authenticated") }

      it "redirects to the OneLogin login page with the original download referer" do
        expect(response).to be_redirect
        expect(response.location).to eq("http://get-energy-performance-data/login/authorize?referer=download%3Ffile%3Doutput%2F323eee63-6c56-4e77-9e36-7699f4cb240.csv")
      end
    end

    context "when no file is found" do
      let(:response) do
        get "#{local_host}?file=none.csv"
      end

      let(:use_case) do
        instance_double(UseCase::GetPresignedUrl)
      end

      let(:app) do
        container = instance_double(Container, get_object: use_case)

        Rack::Builder.new do
          use Rack::Session::Cookie, secret: "test" * 16
          run Controller::FilterPropertiesController.new(container: container)
        end
      end

      around do |example|
        original_stage = ENV["STAGE"]
        ENV["STAGE"] = "mock"
        example.run
        ENV["STAGE"] = original_stage
      end

      after do
        ENV.delete("STAGE")
      end

      before do
        allow(use_case).to receive(:execute).and_raise(Errors::FileNotFound)
      end

      it "raises a 404" do
        expect(response.status).to eq(404)
      end
    end
  end

  describe "get .get-energy-certificate-data.epb-frontend/download/all" do
    let(:local_host) do
      "http://get-energy-performance-data/download/all"
    end

    let(:property_type) do
      "domestic"
    end

    let(:response) do
      get "#{local_host}?property_type=#{property_type}"
    end

    it "returns 302" do
      expect(response.status).to eq(302)
    end

    context "when user is authenticated" do
      before { allow(Helper::Session).to receive(:is_user_authenticated?).and_return(true) }

      it "returns the redirect status" do
        expect(response.status).to eq(302)
      end

      it "redirects to full-load file download" do
        expect(response.headers["location"]).to include("https://user-data.s3.us-stubbed-1.amazonaws.com/full-load/#{property_type}-csv.zip?X-Amz-Algorithm=AWS4-HMAC")
      end
    end

    context "when user is not authenticated" do
      before { allow(Helper::Session).to receive(:is_user_authenticated?).and_raise(Errors::AuthenticationError, "User is not authenticated") }

      it "redirects to the OneLogin login page with the original download all referer" do
        expect(response).to be_redirect
        expect(response.location).to eq("http://get-energy-performance-data/login/authorize?referer=download%2Fall%3Fproperty_type%3Ddomestic")
      end
    end

    context "when no file is found" do
      let(:response) do
        get "#{local_host}?property_type=none"
      end

      let(:use_case) do
        instance_double(UseCase::GetPresignedUrl)
      end

      let(:app) do
        container = instance_double(Container, get_object: use_case)

        Rack::Builder.new do
          use Rack::Session::Cookie, secret: "test" * 16
          run Controller::FilterPropertiesController.new(container: container)
        end
      end

      around do |example|
        original_stage = ENV["STAGE"]
        ENV["STAGE"] = "mock"
        example.run
        ENV["STAGE"] = original_stage
      end

      after do
        ENV.delete("STAGE")
      end

      before do
        allow(use_case).to receive(:execute).and_raise(Errors::FileNotFound)
      end

      it "raises a 404" do
        expect(response.status).to eq(404)
      end
    end

    context "when the request received with invalid property type" do
      before do
        get "#{local_host}?property_type=invalid"
      end

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

  describe "get .get-energy-certificate-data.epb-frontend/download/code" do
    let(:response) do
      get "http://get-energy-performance-data/download/codes"
    end

    it "redirects to the file download" do
      expect(response.headers["location"]).to include("https://user-data.s3.us-stubbed-1.amazonaws.com/codes.csv?X-Amz-Algorithm=AWS4-HMAC")
    end
  end

  describe "get .get-energy-certificate-data.epb-frontend/download/data-dictionary" do
    context "when property_type is valid" do
      let(:property_type) do
        "domestic"
      end

      let(:response) do
        get "http://get-energy-performance-data/download/data-dictionary?property_type=#{property_type}"
      end

      it "calls download_data_dictionary_csv" do
        expect(response.status).to eq(200)
        expect(response.headers["Content-Type"]).to include("text/csv")
        expect(response.headers["Content-Disposition"]).to include("attachment; filename=\"domestic_data_dictionary.csv\"")
      end

      context "when property_type is non-domestic" do
        let(:response) do
          get "http://get-energy-performance-data/download/data-dictionary?property_type=non-domestic"
        end

        it "calls download_data_dictionary_csv with non_domestic value" do
          expect(response.status).to eq(200)
          expect(response.headers["Content-Type"]).to include("text/csv")
          expect(response.headers["Content-Disposition"]).to include("attachment; filename=\"non_domestic_data_dictionary.csv\"")
        end
      end
    end

    context "when property_type is missing" do
      let(:response) do
        get "http://get-energy-performance-data/download/data-dictionary"
      end

      it "returns 404" do
        expect(response.status).to eq(404)
      end

      it "shows the error page" do
        expect(response.body).to include(
          '<h1 class="govuk-heading-xl">Page not found</h1>',
        )
      end
    end

    context "when property_type is invalid" do
      let(:property_type) do
        "invalid_type"
      end

      let(:response) do
        get "http://get-energy-performance-data/download/data-dictionary?property_type=#{property_type}"
      end

      it "returns 404" do
        expect(response.status).to eq(404)
      end

      it "shows the error page" do
        expect(response.body).to include(
          '<h1 class="govuk-heading-xl">Page not found</h1>',
        )
      end
    end
  end
end

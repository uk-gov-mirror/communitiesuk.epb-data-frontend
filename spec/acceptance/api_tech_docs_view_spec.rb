require_relative "../shared_context/shared_api_tech_docs"

describe "Acceptance::ApiTechnicalDocumentation", type: :feature do
  include RSpecFrontendServiceMixin

  let(:base_url) { "http://get-energy-performance-data" }

  describe "get .get-energy-certificate-data.epb-frontend/api-technical-documentation" do
    include_context "when viewing api tech docs"

    let(:path) { "/api-technical-documentation" }

    context "when the start page is rendered" do
      let(:response) { get "#{base_url}#{path}" }

      it "returns status 200" do
        expect(response.status).to eq(200)
      end

      it "has the correct header" do
        expect(response.body).to have_css("h1", text: "Energy certificate data API documentation")
      end

      it "displays the tab value the same as the main header value" do
        expect(response.body).to include("Energy certificate data API documentation – GOV.UK</title>")
      end

      it "has the navigation component" do
        expect(response.body).to have_css("nav.app-subnav")
      end

      it "the navigation has a link to each page" do
        expect(response.body).to have_css("ul.app-subnav__section li", count: 25)
      end

      it "the navigation has a 2 sections" do
        expect(response.body).to have_css("nav h3", text: "General documentation")
        expect(response.body).to have_css("nav h3", text: "API specifications")
      end

      it "has the correct content for rate limiting section" do
        expect(response.body).to have_css("h2", text: "Rate limiting")
        expect(response.body).to have_css("p", text: "If you continually hit this rate limit, contact us to discuss your application design and whether it’s appropriate to raise your rate limit.")
      end

      it "has the expected navigation links" do
        page_urls.each do |link|
          url = "#{path}/#{link}"
          expect(response.body).to have_css("ul.app-subnav__section li a[href='#{url}']")
        end
      end
    end

    context "when requesting each api document" do
      it "returns status 200 for each page" do
        page_urls.each do |link|
          response = get "#{base_url}#{path}/#{link}"
          expect(response.status).to eq(200)
        end
      end

      it "displays the title the same as the main header value for pages" do
        page_urls.each_with_index do |link, index|
          response = get "#{base_url}#{path}/#{link}"
          expect(response.body).to have_title "#{page_titles[index]} – GOV.UK"
        end
      end

      it "each page has the correct sections" do
        page_urls.each do |link|
          response = get "#{base_url}#{path}/#{link}"
          expect(response.body).to have_css("ul.app-subnav__section")
          expect(response.body).to have_css("h1")
          expect(response.body).to have_css("h2")
        end
      end

      it "each page has the current link class" do
        page_urls.each do |link|
          response = get "#{base_url}#{path}/#{link}"
          url = "#{path}/#{link}"
          expect(response.body).to have_css("li.app-subnav__section-item--current", count: 1)
          expect(response.body).to have_css("li.app-subnav__section-item--current a[href='#{url}']")
        end
      end

      context "when calling the pages that document endpoints" do
        it "each page has the expected sections" do
          end_points.each do |link|
            response = get "#{base_url}#{path}/#{link}"
            expect(response.body).to have_css("h2", text: "Method")
            expect(response.body).to have_css("h2", text: "Response")
            expect(response.body).to have_css("h2", text: "Example")
            expect(response.body).to include('curl <span class="s2">"http://api.get-energy-performance-data/api/')
          end
        end

        context "when calling the end point documents that have params" do
          it "each page has the expected sections" do
            end_points_params.each do |link|
              response = get "#{base_url}#{path}/#{link}"
              expect(response.body).to have_css("h2", text: "Parameters")
            end
          end
        end
      end
    end

    context "when the making a request page is rendered" do
      it "show the published url to API" do
        response = get "#{base_url}#{path}/making-a-request"
        expect(response.body).to have_css("code", text: "http://api.get-energy-performance-data")
      end

      it "show the correct curl command to API" do
        response = get "#{base_url}#{path}/making-a-request"
        expect(response.body).to include('curl <span class="s2">"http://api.get-energy-performance-data/api/')
      end
    end

    context "when requesting the codes page" do
      let(:response) { get "#{base_url}#{path}/codes" }

      it "displays the download link header" do
        expect(response.body).to have_css("h3", text: "Download in csv format")
      end

      it "displays the download link" do
        expect(response.body).to have_link("Download codes", href: "/download/codes")
      end
    end
  end
end

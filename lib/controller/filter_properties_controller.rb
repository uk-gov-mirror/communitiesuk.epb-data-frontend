module Controller
  class FilterPropertiesController < Controller::BaseController
    filter_properties =
      lambda do
        @errors = {}
        @error_form_ids = []
        @back_link_href = "/type-of-properties"

        email_address = Helper::Session.get_email_from_session(session)

        property_type = params["property_type"]
        raise Errors::InvalidPropertyType unless property_type_valid?(property_type)

        @page_title = "#{t("filter_properties.#{property_type}_title")} – #{t('layout.body.govuk')}"
        status 200

        params["ratings"] ||= %w[A B C D E F G] unless request.post?

        if request.post?
          validate_date
          validate_area
          validate_postcode
          validate_ratings if property_type == "domestic"
        end

        if request.post? && @errors.empty?
          redirect "/download/all?property_type=#{property_type}" if default_filters?(property_type)

          download_count = get_download_size(params, property_type:)
          raise Errors::FilteredDataNotFound if download_count.zero?

          Helper::Session.set_session_value(session, :download_count, download_count)
          send_download_request(email_address:, property_type:)
          form_data = Rack::Utils.build_nested_query(params)
          redirect "/request-received-confirmation?#{form_data}"
        else
          erb :filter_properties, locals: { use_case: @container.get_object(:get_file_size_use_case) }
        end
      rescue StandardError => e
        case e
        when Errors::FilteredDataNotFound
          status 400
          @errors[:data_not_found] = t("error.data_not_found")
          @error_form_ids << "filter-properties-header"
          erb :filter_properties, locals: { use_case: @container.get_object(:get_file_size_use_case) }
        when Errors::SessionEmailError
          redirect "/signed-out"
        when Errors::UserEmailNotVerified, Errors::AuthenticationError, Errors::NetworkError
          logger.warn "Authentication error: #{e.message}"
          redirect "/login/authorize?referer=filter-properties"
        when Errors::InvalidPropertyType
          @page_title = "#{t('error.error')}#{
            t('error.download_file.heading')
          } – #{t('error.download_file.invalid_property_type')} – #{
            t('layout.body.govuk')
          }"
          status 404
          erb :error_page_404
        else
          logger.error "Unexpected error during filter_properties: #{e.message}"
          server_error(e)
        end
      end

    get "/filter-properties",
        &filter_properties

    post "/filter-properties",
         &filter_properties

    get "/request-received-confirmation" do
      check_referral
      @page_title = "#{t('request_received.title')} – #{t('layout.body.govuk')}"

      email = Helper::Session.get_email_from_session(session)
      property_type = params["property_type"]
      raise Errors::InvalidPropertyType unless property_type_valid?(property_type)

      download_count = Helper::Session.get_download_count_from_session(session)

      @back_link_href = "/filter-properties?property_type=#{property_type}"

      status 200

      erb :request_received_confirmation, locals: { email:, download_count: }
    rescue StandardError => e
      case e
      when Errors::InvalidPropertyType
        @page_title = "#{t('error.error')}#{
          t('error.download_file.heading')
        } – #{t('error.download_file.invalid_property_type')} – #{
          t('layout.body.govuk')
        }"
        status 404
      when Errors::SessionEmailError
        redirect "/signed-out"
      else
        logger.error "Unexpected error during filter_properties: #{e.message}"
        server_error(e)
      end
    end

  private

    def check_referral
      referrer_url = request.referrer
      access_forbidden unless referrer_url

      uri = URI(referrer_url)

      same_origin = uri.scheme == request.scheme &&
        uri.host == request.host &&
        uri.port == request.port

      access_forbidden unless same_origin && uri.path == "/filter-properties"
    end

    def access_forbidden
      logger.warn "Invalid referrer detected. Access Forbidden"
      halt 403, erb(:error_page_403)
    end

    def get_download_size(params_data, property_type:)
      use_case = @container.get_object(:get_download_size_use_case)
      date_start = ViewModels::FilterProperties.start_date_from_inputs(params_data["from-year"], params_data["from-month"]).to_s
      date_end = ViewModels::FilterProperties.end_date_from_inputs(params_data["to-year"], params_data["to-month"]).to_s

      council = if params_data["local-authority"] != ["Select all"] && params_data["area-type"] == "local-authority"
                  params_data[params_data["area-type"]]
                end

      constituency = if params_data["parliamentary-constituency"] != ["Select all"] && params_data["area-type"] == "parliamentary-constituency"
                       params_data[params_data["area-type"]]
                     end

      postcode = if params_data["area-type"] == "postcode"
                   params_data[params_data["area-type"]]
                 end

      eff_rating = params_data["ratings"]

      use_case_args = {
        postcode:,
        council:,
        constituency:,
        eff_rating:,
        date_start:,
        date_end:,
        property_type:,
      }

      use_case.execute(**use_case_args)
    end

    def send_download_request(email_address:, property_type:)
      area_value = params[params["area-type"]]
      date_start = ViewModels::FilterProperties.start_date_from_inputs(params["from-year"], params["from-month"])
      date_end = ViewModels::FilterProperties.end_date_from_inputs(params["to-year"], params["to-month"])

      use_case_args = {
        property_type:,
        date_start:,
        date_end:,
        area_type: params["area-type"],
        area_value:,
        efficiency_ratings: params["ratings"] || nil,
        include_recommendations: params["recommendations"] || nil,
        email_address:,
      }
      use_case = @container.get_object(:send_download_request_use_case)
      use_case.execute(**use_case_args)
    end

    def default_filters?(property_type)
      non_domestic_and_dec_default_filters = {
        "from-month" => "January",
        "from-year" => "2012",
        "to-month" => ViewModels::FilterProperties.previous_month,
        "to-year" => ViewModels::FilterProperties.current_year,
        "postcode" => "",
        "local-authority" => ["Select all"],
        "parliamentary-constituency" => ["Select all"],
      }

      domestic_default_filters = non_domestic_and_dec_default_filters.merge({ "ratings" => %w[A B C D E F G] })

      if property_type == "domestic"
        domestic_default_filters.all? { |key, value| params[key] == value }
      else
        non_domestic_and_dec_default_filters.all? { |key, value| params[key] == value }
      end
    end

    def validate_date
      return if ViewModels::FilterProperties.is_valid_date?(params)

      status 400
      @error_form_ids << "date-section"
      @errors[:date] = t("error.invalid_filter_option.date_invalid")
    end

    def validate_area
      params["local-authority"] ? params["local-authority"] : params["local-authority"] = ["Select all"]
      params["parliamentary-constituency"] ? params["parliamentary-constituency"] : params["parliamentary-constituency"] = ["Select all"]
    end

    def validate_postcode
      params["postcode"].strip! unless params["postcode"].nil?
      return unless params["area-type"] == "postcode" && !(params["postcode"].nil? || params["postcode"].empty?)

      begin
        postcode_check = Helper::PostcodeValidator.validate(params.fetch("postcode", ""))
      rescue Errors::PostcodeIncomplete
        status 400
        @error_form_ids << "area-type-section"
        @errors[:postcode] = t("error.invalid_filter_option.postcode_incomplete")
      rescue Errors::PostcodeWrongFormat
        status 400
        @error_form_ids << "area-type-section"
        @errors[:postcode] = t("error.invalid_filter_option.postcode_wrong_format")
      rescue Errors::PostcodeNotValid
        status 400
        @error_form_ids << "area-type-section"
        @errors[:postcode] = t("error.invalid_filter_option.postcode_invalid")
      else
        params["postcode"] = postcode_check
      end
    end

    def validate_ratings
      return unless params["ratings"].nil? || params["ratings"].empty?

      status 400
      @error_form_ids << "eff-rating-section"
      @errors[:eff_rating] = t("error.invalid_filter_option.eff_rating_invalid")
    end
  end
end

module Controller
  class UserController < BaseController
    get "/login" do
      status 200
      @page_title = "#{t('login.title')} – #{t('layout.body.govuk')}"

      if params["referer"] == "opt-out"
        @hide_my_account = true
        @hide_banner_text = true

        owner = Helper::Session.get_session_value(session, :opt_out_owner)
        occupant = Helper::Session.get_session_value(session, :opt_out_occupant)

        if owner.nil? && occupant.nil?
          redirect localised_url("/opt-out")
        end

        unless owner == "yes" || occupant == "yes"
          redirect localised_url("/opt-out/ineligible")
        end
      end

      authorize_url = "/login/authorize?referer=opt-out"
      erb :login, locals: { authorize_url: }
    rescue StandardError => e
      server_error(e)
    end

    get "/login/authorize" do
      client_id = ENV["ONELOGIN_CLIENT_ID"]
      host_url = ENV["ONELOGIN_HOST_URL"]
      frontend_url = "#{request.scheme}://#{request.host_with_port}"
      aud = "#{host_url}/authorize"
      redirect_uri = "#{frontend_url}/login/callback"

      Helper::Session.set_session_value(session, :referer, params["referer"])

      nonce = Helper::Session.get_session_value(session, :nonce) || SecureRandom.hex(16)
      state = Helper::Session.get_session_value(session, :state) || SecureRandom.hex(16)

      Helper::Session.set_session_value(session, :nonce, nonce)
      Helper::Session.set_session_value(session, :state, state)

      use_case = @container.get_object(:sign_onelogin_request_use_case)

      use_case_args = {
        aud:,
        client_id:,
        redirect_uri:,
        state:,
        nonce:,
      }

      signed_request = use_case.execute(**use_case_args)

      query_string = URI.encode_www_form({
        client_id: client_id,
        scope: "openid email",
        response_type: "code",
        request: signed_request,
      })
      redirect localised_url("#{host_url}/authorize?#{query_string}")
    end

    get "/login/callback" do
      referer = Helper::Session.get_session_value(session, :referer)
      nonce = Helper::Session.get_session_value(session, :nonce)

      raise Errors::AuthenticationError, "No referer found in session" if referer.nil? || referer.empty?

      redirect_path = CGI.unescape(referer)
      validate_one_login_callback
      token_response_hash = exchange_code_for_token(callback_path: request.path)

      use_case = @container.get_object(:validate_id_token_use_case)
      is_valid = use_case.execute(token_response_hash:, nonce:)

      raise Errors::ValidationError, "ID token validation failed" unless is_valid

      is_opt_out = redirect_path == "opt-out"

      Helper::Onelogin.set_user_one_login_info(container: @container, session:, token_response_hash:, is_opt_out:)

      if is_opt_out
        redirect_path = "opt-out/name"
      end

      query_union = redirect_path.include?("?") ? "&" : "?"
      redirect "/#{redirect_path}#{query_union}nocache=#{Time.now.to_i}"
    rescue StandardError => e
      case e
      when Errors::StateMismatch, Errors::AccessDeniedError, Errors::LoginRequiredError, Errors::InvalidGrantError
        message =
          e.methods.include?(:message) ? e.message : e

        error = { type: e.class.name, message: }
        error[:backtrace] = e.backtrace if e.methods.include? :backtrace
        @logger.error JSON.generate(error)

        redirect_link = redirect_path == "opt-out" ? "/login?referer=opt-out" : "/login/authorize?referer=#{referer}"

        redirect localised_url(redirect_link)
      when Errors::TokenExchangeError, Errors::AuthenticationError, Errors::NetworkError, Errors::ValidationError
        @logger.warn "Authentication error: #{e.message}"
        server_error(e)
      else
        @logger.error "Unexpected error during login callback: #{e.message}"
        server_error(e)
      end
    end

    get "/jwks" do
      status 200
      response.content_type = "application/json"
      onelogin_keys = JSON.parse(ENV["ONELOGIN_TLS_KEYS"])
      public_key_pem = onelogin_keys["public_key"]
      public_key = OpenSSL::PKey::RSA.new(public_key_pem)

      jwk = JWT::JWK.new(public_key)
      jwks_hash = jwk.export
      jwks_hash[:kid] = onelogin_keys["kid"]
      jwks_hash[:use] = "sig"

      { keys: [jwks_hash] }.to_json
    rescue StandardError => e
      server_error(e)
    end

    get "/signed-out" do
      status 200
      @page_title = "#{t('signed_out.title')} – #{t('layout.body.govuk')}"

      erb :signed_out
    end

    get "/sign-out" do
      host_url = "#{ENV['ONELOGIN_HOST_URL']}/logout"
      frontend_url = "#{request.scheme}://#{request.host_with_port}"
      redirect_uri = "#{frontend_url}/signed-out"

      query_string = URI.encode_www_form({
        id_token_hint: Helper::Session.get_session_value(session, :id_token),
        post_logout_redirect_uri: redirect_uri,
      })
      Helper::Session.clear_session(session)
      redirect "#{host_url}?#{query_string}"
    end

    def validate_one_login_callback
      received_state = params[:state]
      stored_state = session[:state]

      Helper::Onelogin.validate_state_cookie(received_state, stored_state)
      Helper::Onelogin.check_one_login_errors(params)

      session.delete(:state)
      session.delete(:nonce)
    end

    def exchange_code_for_token(callback_path:)
      frontend_url = "#{request.scheme}://#{request.host_with_port}"
      redirect_uri = "#{frontend_url}#{callback_path}"

      authorisation_code = params[:code]

      use_case_args = {
        code: authorisation_code,
        redirect_uri: redirect_uri,
      }
      use_case = @container.get_object(:request_onelogin_token_use_case)
      use_case.execute(**use_case_args)
    end
  end
end

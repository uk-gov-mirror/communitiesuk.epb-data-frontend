require "erubis"
require "i18n"
require "i18n/backend/fallbacks"
require "sinatra/base"
require "sinatra/cookies"
require_relative "../container"
require_relative "../helper/toggles"

module Controller
  class BaseController < Sinatra::Base
    RESTRICTED_PATHS = %w[/type-of-properties /api/my-account /api/my-account/delete-account /filter-properties /download /download/all /opt-out/name /opt-out/check-your-answers /opt-out/received /opt-out/certificate-details].freeze
    VALID_PROPERTY_TYPES = %w[domestic non-domestic display].freeze

    helpers Helpers
    attr_reader :toggles

    set :views, "lib/views"
    set :erb, escape_html: true
    set :public_folder, proc { File.join(root, "/../../public") }
    set :static_cache_control, [:public, { max_age: 60 * 60 * 24 * 7 }] if ENV["ASSETS_VERSION"]

    if ENV["STAGE"] == "test"
      require "capybara-lockstep"
      include Capybara::Lockstep::Helper
      set :show_exceptions, :after_handler
    end

    get "/" do
      status 200
      @allow_indexing = true
      erb :start_page
    end

    def initialize(*args, container: nil)
      super
      setup_locales
      @toggles = Helper::Toggles
      @container = container || Container.new
      @logger = Logger.new($stdout)
      @logger.level = Logger::FATAL
    end

    HOST_NAME = "get-energy-certificate-data".freeze
    Helper::Assets.setup_cache_control(self)

    before do
      set_locale
      if is_restricted?
        Helper::Session.is_user_authenticated?(session)
      end
      raise MaintenanceMode if request.path != "/healthcheck" && Helper::Toggles.enabled?("ebp-data-frontend-maintenance-mode")
    rescue Errors::AuthenticationError
      login_url = if request.path.start_with?("/opt-out")
                    "/login?referer=opt-out"
                  else
                    referrer = request.fullpath.delete_prefix("/")
                    encoded_referrer = CGI.escape(referrer)
                    "/login/authorize?referer=#{encoded_referrer}"
                  end

      redirect login_url, request.post? ? 303 : 302
    end

    configure :development do
      require "sinatra/reloader"
      register Sinatra::Reloader
      also_reload "lib/**/*.rb"
      set :host_authorization, { permitted_hosts: [] }
    end

    def show(template, locals, layout = :layout)
      locals[:errors] = @errors
      erb template, layout:, locals:
    end

    not_found do
      @page_title = "#{t('error.404.heading')} – #{t('layout.body.govuk')}"
      status 404
      erb :error_page_404 unless @errors
    end

    class MaintenanceMode < RuntimeError
      include Errors::DoNotReport
    end

    error MaintenanceMode do
      status 503
      @page_title =
        "#{t('service_unavailable.title')} – #{t('layout.body.govuk')}"
      erb :service_unavailable
    end

    def send_to_sentry(exception)
      was_timeout = exception.is_a?(Errors::RequestTimeoutError)
      Sentry.capture_exception(exception) if defined?(Sentry) && !was_timeout
    end

    def server_error(exception)
      was_timeout = exception.is_a?(Errors::RequestTimeoutError)
      Sentry.capture_exception(exception) if defined?(Sentry) && !was_timeout

      message =
        exception.methods.include?(:message) ? exception.message : exception

      error = { type: exception.class.name, message: }

      error[:backtrace] = exception.backtrace if exception.methods.include? :backtrace

      @logger.error JSON.generate(error)
      @page_title =
        "#{t('error.500.heading')} – #{t('layout.body.govuk')}"
      status(was_timeout ? 504 : 500)
      erb :error_page_500
    end

    def is_restricted?
      RESTRICTED_PATHS.include?(request.path) || false
    end

    def property_type_valid?(property_type)
      VALID_PROPERTY_TYPES.include?(property_type)
    end
  end
end

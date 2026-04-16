# frozen_string_literal: true

module Helper
  module ReferrerCheck
    def check_referral(referrer_path)
      referrer_url = request.referrer
      access_forbidden unless referrer_url

      uri = URI(referrer_url)

      same_origin = uri.scheme == request.scheme &&
        uri.host == request.host &&
        uri.port == request.port

      access_forbidden unless same_origin && uri.path == referrer_path
    end

    def access_forbidden
      logger.warn "Invalid referrer detected. Access Forbidden"
      halt 403, erb(:error_page_403)
    end
  end
end

module Helper
  class Session
    def self.set_session_value(session, key, value)
      session[key] = value
    end

    def self.exists?(session, key)
      session.key?(key)
    end

    def self.get_session_value(session, key)
      session[key] if exists?(session, key)
    end

    def self.delete_session_key(session, key)
      session.delete(key) if exists?(session, key)
    end

    def self.clear_session(session)
      session.clear
    end

    def self.get_email_from_session(session)
      email = get_session_value(session, :email_address)
      raise Errors::SessionEmailError unless email

      email
    end

    def self.get_download_count_from_session(session)
      download_count = get_session_value(session, :download_count)
      raise Errors::MissingDownloadCount unless download_count

      download_count
    end

    def self.get_opt_out_session_value(session, key)
      opt_out_key = get_session_value(session, :opt_out)
      opt_out_key[key]
    end

    def self.is_user_authenticated?(session)
      raise Errors::AuthenticationError, "Session is not available" if session.nil?

      email = get_session_value(session, :email_address)
      raise Errors::AuthenticationError, "User email is not set in session" if email.nil? || email.empty?

      true
    end

    def self.is_logged_in?(session)
      return false if session.nil?

      email = get_session_value(session, :email_address)
      return false if email.nil? || email.empty?

      true
    end
  end
end

module Controller
  class ApiController < Controller::BaseController
    include Helper::ReferrerCheck

    get "/api/my-account/toggle-email-notifications" do
      toggle_email_notifications_use_case = @container.get_object(:toggle_email_notifications_use_case)
      user_id = Helper::Session.get_session_value(session, :user_id)
      toggle_email_notifications_use_case.execute(user_id)
      redirect "/api/my-account"
    end

    get "/api/my-account" do
      status 200
      @back_link_href = request.referer || "/"
      @page_title = "#{t('my_account.title')} – #{t('layout.body.govuk')}"

      get_user_info_use_case = @container.get_object(:get_user_info_use_case)

      user_id = Helper::Session.get_session_value(session, :user_id)
      user_info = get_user_info_use_case.execute(user_id)

      erb :my_account, locals: { user_info: }
    rescue StandardError => e
      case e
      when Errors::BearerTokenMissing
        logger.warn "Bearer token missing: #{e.message}"
        redirect "/login/authorize?referer=api/my-account"
      when Errors::UserMissing
        logger.warn "User information from user-credentials missing: #{e.message}"
        redirect "/login/authorize?referer=api/my-account"
      else
        logger.error "Unexpected error during /api/my-account get endpoint: #{e.message}"
        server_error(e)
      end
    end

    get "/api/my-account/delete-account" do
      status 200
      @back_link_href = request.referer || "/api/my-account"
      @page_title = "#{t('delete_account.title')} – #{t('layout.body.govuk')}"
      erb :delete_account
    rescue StandardError => e
      server_error(e)
    end

    post "/api/my-account/delete-account" do
      user_id = Helper::Session.get_session_value(session, :user_id)
      unless user_id.nil?
        use_case = @container.get_object(:delete_user_use_case)
        use_case.execute(user_id)
      end

      Helper::Session.clear_session(session)
      redirect "/account-deleted"
    rescue StandardError => e
      server_error(e)
    end

    get "/account-deleted" do
      check_referral("/api/my-account/delete-account")
      status 200
      @page_title = "#{t('delete_account.account_deleted')} – #{t('layout.body.govuk')}"
      erb :account_deleted
    rescue StandardError => e
      server_error(e)
    end
  end
end

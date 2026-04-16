# frozen_string_literal: true

require "aws-sdk-sns"
require "aws-sdk-s3"
require "notifications/client"

class Container
  def initialize
    count_api_client = Auth::HttpClient.new ENV["EPB_AUTH_CLIENT_ID"],
                                            ENV["EPB_AUTH_CLIENT_SECRET"],
                                            ENV["EPB_AUTH_SERVER"],
                                            ENV["EPB_DATA_WAREHOUSE_API_URL"],
                                            OAuth2::Client,
                                            faraday_connection_opts: { request: { timeout: 60 } }

    notify_client = Notifications::Client.new(ENV["NOTIFY_DATA_API_KEY"])

    sns_gateway = Gateway::SnsGateway.new
    certificate_count_gateway = Gateway::CertificateCountGateway.new(count_api_client)
    onelogin_gateway = Gateway::OneloginGateway.new
    kms_gateway = Gateway::KmsGateway.new
    user_credentials_gateway = Gateway::UserCredentialsGateway.new(kms_gateway: kms_gateway)
    notify_gateway = Gateway::NotifyGateway.new(notify_client)

    send_download_request_use_case = UseCase::SendDownloadRequest.new(sns_gateway:, topic_arn: ENV["SEND_DOWNLOAD_TOPIC_ARN"])
    get_download_size_use_case = UseCase::GetDownloadSize.new(certificate_count_gateway:)
    get_presigned_url_use_case = UseCase::GetPresignedUrl.new(gateway: Gateway::S3Gateway.new, bucket_name: ENV["AWS_S3_USER_DATA_BUCKET_NAME"])
    sign_onelogin_request_use_case = UseCase::SignOneloginRequest.new
    request_onelogin_token_use_case = UseCase::RequestOneloginToken.new(onelogin_gateway:)
    get_onelogin_user_info_use_case = UseCase::GetOneloginUserInfo.new(onelogin_gateway:)
    get_user_id_use_case = UseCase::GetUserId.new(user_credentials_gateway:)
    get_user_info_use_case = UseCase::GetUserInfo.new(user_credentials_gateway:)
    toggle_email_notifications_use_case = UseCase::ToggleUserEmailNotifications.new(user_credentials_gateway:)
    delete_user_use_case = UseCase::DeleteUser.new(user_credentials_gateway:)
    get_file_size_use_case = UseCase::GetFileSize.new(gateway: Gateway::S3Gateway.new, bucket_name: ENV["AWS_S3_USER_DATA_BUCKET_NAME"])
    send_opt_out_request_email_use_case = UseCase::SendOptOutRequestEmail.new(notify_gateway:)
    validate_id_token_use_case = UseCase::ValidateIdToken.new(onelogin_gateway:, cache: Helper::JwksDocumentCache.new)
    @objects = {
      send_download_request_use_case:,
      get_download_size_use_case:,
      get_presigned_url_use_case:,
      sign_onelogin_request_use_case:,
      request_onelogin_token_use_case:,
      get_onelogin_user_info_use_case:,
      get_user_id_use_case:,
      get_user_info_use_case:,
      toggle_email_notifications_use_case:,
      delete_user_use_case:,
      get_file_size_use_case:,
      send_opt_out_request_email_use_case:,
      validate_id_token_use_case:,
    }
  end

  def get_object(key)
    @objects[key]
  end
end

module UseCase
  class DeleteUser
    def initialize(user_credentials_gateway:)
      @user_credentials_gateway = user_credentials_gateway
    end

    def execute(user_id)
      @user_credentials_gateway.delete_user(user_id)
    end
  end
end

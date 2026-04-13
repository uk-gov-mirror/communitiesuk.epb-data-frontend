class Helper::StubUsersCredentials
  def initialize(users)
    @users = users.split(",").map(&:strip)
  end

  def get_opt_in_users
    @users
  end
end

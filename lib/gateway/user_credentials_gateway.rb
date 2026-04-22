require "aws-sdk-dynamodb"

module Gateway
  class UserCredentialsGateway
    def initialize(kms_gateway:, dynamo_db_client: nil)
      @kms_gateway = kms_gateway
      table_name = ENV["EPB_DATA_USER_CREDENTIAL_TABLE_NAME"]
      client = dynamo_db_client || get_dynamo_db_client
      @table = Aws::DynamoDB::Table.new(table_name, client:)
    end

    def insert_user(one_login_sub:, email:)
      user_id = SecureRandom.uuid
      encrypted_email = @kms_gateway.encrypt(email)

      new_user = {
        "UserId" => user_id,
        "CreatedAt" => Time.now.to_s,
        "BearerToken" => SecureRandom.alphanumeric(64),
        "OneLoginSub" => one_login_sub,
        "EmailAddress" => encrypted_email,
        "OptOut" => false,
      }

      @table.put_item(
        item: new_user,
      )
      user_id
    end

    def update_user_email(user_id:, email:)
      user = @table.get_item(key: { "UserId" => user_id }).item
      updated_user = user.dup

      encrypted_email = @kms_gateway.encrypt(email)
      updated_user.merge!("EmailAddress" => encrypted_email)
      updated_user.merge!("OptOut" => false) if updated_user["OptOut"].nil?

      @table.put_item(
        item: updated_user,
      )
    end

    def get_user(one_login_sub)
      items = []
      params = {
        filter_expression: "OneLoginSub = :sub",
        expression_attribute_values: {
          ":sub" => one_login_sub,
        },
      }

      scan_all_pages(params) do |page_items|
        items.concat(page_items)
      end

      items.count.zero? ? nil : items.first["UserId"]
    end

    def get_user_token(user_id)
      response = @table.get_item(
        key: {
          "UserId" => user_id,
        },
      )
      raise Errors::BearerTokenMissing unless response.item

      response.item["BearerToken"]
    end

    def get_user_info(user_id)
      raise Errors::UserMissing if user_id.nil?

      response = @table.get_item(
        key: {
          "UserId" => user_id,
        },
      )
      raise Errors::UserMissing unless response.item

      {
        bearer_token: response.item["BearerToken"],
        opt_out: response.item["OptOut"] || false,
      }
    end

    def toggle_user_opt_out(user_id)
      user = @table.get_item(key: { "UserId" => user_id }).item

      updated_user = user.dup
      current_opt_out = updated_user["OptOut"] || false
      updated_user.merge!("OptOut" => !current_opt_out)

      @table.put_item(
        item: updated_user,
      )
    end

    def delete_user(user_id)
      @table.delete_item(
        key: { "UserId" => user_id },
      )
    end

  private

    def scan_all_pages(params)
      loop do
        resp = @table.scan(params)
        yield resp.items
        break unless resp.last_evaluated_key

        params[:exclusive_start_key] = resp.last_evaluated_key
      end
    end

    def get_dynamo_db_client
      if Aws.config.dig(:dynamodb, :client)
        Aws.config[:dynamodb][:client]
      elsif ["local", nil].include?(ENV["APP_ENV"])
        Aws::DynamoDB::Client.new(stub_responses: true)
      else
        Aws::DynamoDB::Client.new(region: "eu-west-2")
      end
    end
  end
end

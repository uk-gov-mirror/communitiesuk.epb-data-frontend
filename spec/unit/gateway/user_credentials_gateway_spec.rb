require "aws-sdk-dynamodb"

describe Gateway::UserCredentialsGateway do
  subject(:gateway) { described_class.new(dynamo_db_client:, kms_gateway:) }

  let(:kms_gateway) { instance_double(Gateway::KmsGateway) }

  let(:dynamo_db_client) do
    Aws::DynamoDB::Client.new(
      region: "eu-west-2",
      credentials: Aws::Credentials.new("fake_access_key_id", "fake_secret_access_key"),
    )
  end

  let(:user_id) do
    "e40c46c3-4636-4a8a-abd7-be72e1a525f6"
  end

  let(:sub_id) do
    "mock-sub-id"
  end

  let(:email) do
    "test@email.com"
  end

  describe "#insert_user" do
    context "when inserting a new user" do
      let(:encrypted_email) { "encrypted-email" }
      let(:expected_put_item_body) do
        {
          "Item": {
            "UserId": {
              "S": user_id,
            },
            "CreatedAt": {
              "S": Time.utc(2025, 6, 25, 12, 32),
            },
            "BearerToken": {
              "S": "D0RnC2oKGsoM936wKmtd4ZcoSw489rPo4FDqQ2SYQVtVnQ4PhZ33b46YZPNZXo6r",
            },
            "OneLoginSub": {
              "S": sub_id,
            },
            "EmailAddress": {
              "S": encrypted_email,
            },
            "OptOut": {
              "BOOL": false,
            },
          },
          "TableName": "test_users_table",
        }.to_json
      end

      before do
        Timecop.freeze(Time.utc(2025, 6, 25, 12, 32, 0))
        allow(SecureRandom).to receive_messages(
          uuid: user_id,
          alphanumeric: "D0RnC2oKGsoM936wKmtd4ZcoSw489rPo4FDqQ2SYQVtVnQ4PhZ33b46YZPNZXo6r",
        )
        allow(kms_gateway).to receive(:encrypt).with(email).and_return(encrypted_email)

        WebMock.stub_request(:post, "https://dynamodb.eu-west-2.amazonaws.com")
          .with(body: expected_put_item_body,
                headers: {
                  "X-Amz-Target" => "DynamoDB_20120810.PutItem",
                })
          .to_return(status: 200, body: "{}")
      end

      after do
        Timecop.return
      end

      it "inserts the user and returns the userId" do
        expect(gateway.insert_user(one_login_sub: sub_id, email: email)).to eq(user_id)
      end

      it "encrypts the email using KmsGateway" do
        gateway.insert_user(one_login_sub: sub_id, email: email)
        expect(kms_gateway).to have_received(:encrypt).with(email).once
      end
    end
  end

  describe "#update_user_email" do
    let(:encrypted_email) { "encrypted-email" }

    before do
      allow(kms_gateway).to receive(:encrypt).with(email).and_return(encrypted_email)
    end

    context "when the user is missing the EmailAddress information" do
      let(:user_missing_email_body) do
        {
          "Item" => {
            "UserId" => { "S" => user_id },
            "OneLoginSub" => { "S" => "sub_abcdef123" },
            "BearerToken" => { "S" => "token123" },
            "CreatedAt" => { "S" => "2025-03-05T11:00:00Z" },
          },
        }
      end

      before do
        WebMock.stub_request(:post, "https://dynamodb.eu-west-2.amazonaws.com/")
         .with(headers: { "X-Amz-Target" => "DynamoDB_20120810.GetItem" })
         .to_return(
           status: 200,
           body: user_missing_email_body.to_json,
           headers: { "Content-Type" => "application/x-amz-json-1.0" },
         )
        WebMock.stub_request(:post, "https://dynamodb.eu-west-2.amazonaws.com/")
               .with(headers: { "X-Amz-Target" => "DynamoDB_20120810.PutItem" })
               .to_return(status: 200, body: "", headers: {})
      end

      it "updates the email into the user credentials table" do
        expected_body = {
          "Item" => {
            "UserId" => { "S" => user_id },
            "OneLoginSub" => { "S" => "sub_abcdef123" },
            "BearerToken" => { "S" => "token123" },
            "CreatedAt" => { "S" => "2025-03-05T11:00:00Z" },
            "EmailAddress" => { "S" => encrypted_email },
            "OptOut" => { "BOOL": false },
          },
          "TableName" => ENV["EPB_DATA_USER_CREDENTIAL_TABLE_NAME"] || "test_users_table",
        }.to_json

        gateway.update_user_email(user_id:, email:)

        expect(WebMock).to have_requested(:post, "https://dynamodb.eu-west-2.amazonaws.com/")
                             .with(
                               body: expected_body,
                               headers: { "X-Amz-Target" => "DynamoDB_20120810.PutItem" },
                             )
      end
    end

    context "when the user is missing the OptOut information" do
      let(:user_missing_opt_out_body) do
        {
          "Item" => {
            "UserId" => { "S" => user_id },
            "OneLoginSub" => { "S" => "sub_abcdef123" },
            "BearerToken" => { "S" => "token123" },
            "CreatedAt" => { "S" => "2025-03-05T11:00:00Z" },
            "EmailAddress" => { "S" => encrypted_email },
          },
        }
      end

      before do
        WebMock.stub_request(:post, "https://dynamodb.eu-west-2.amazonaws.com/")
               .with(headers: { "X-Amz-Target" => "DynamoDB_20120810.GetItem" })
               .to_return(
                 status: 200,
                 body: user_missing_opt_out_body.to_json,
                 headers: { "Content-Type" => "application/x-amz-json-1.0" },
               )
        WebMock.stub_request(:post, "https://dynamodb.eu-west-2.amazonaws.com/")
               .with(headers: { "X-Amz-Target" => "DynamoDB_20120810.PutItem" })
               .to_return(status: 200, body: "", headers: {})
      end

      it "updates the OptOut with the default into the user credentials table" do
        expected_body = {
          "Item" => {
            "UserId" => { "S" => user_id },
            "OneLoginSub" => { "S" => "sub_abcdef123" },
            "BearerToken" => { "S" => "token123" },
            "CreatedAt" => { "S" => "2025-03-05T11:00:00Z" },
            "EmailAddress" => { "S" => encrypted_email },
            "OptOut" => { "BOOL": false },
          },
          "TableName" => ENV["EPB_DATA_USER_CREDENTIAL_TABLE_NAME"] || "test_users_table",
        }.to_json

        gateway.update_user_email(user_id:, email:)

        expect(WebMock).to have_requested(:post, "https://dynamodb.eu-west-2.amazonaws.com/")
                             .with(
                               body: expected_body,
                               headers: { "X-Amz-Target" => "DynamoDB_20120810.PutItem" },
                             )
      end
    end
  end

  describe "#get_user" do
    context "when getting an existing user" do
      let(:expected_query_body) do
        {
          "FilterExpression":
            "OneLoginSub = :sub",
          "ExpressionAttributeValues": {
            ":sub": { "S": sub_id },
          },
          "TableName": "test_users_table",
        }.to_json
      end

      let(:query_response) do
        {
          "Items" => [
            {
              "UserId" => { "S" => user_id },
              "OneLoginSub" => { "S" => sub_id },
              "CreatedAt" => { "S" => Time.now.to_s },
              "BearerToken" => { "S" => "the-bearer-token" },
            },
          ],
          "Count" => 1,
        }.to_json
      end

      before do
        WebMock.stub_request(:post, "https://dynamodb.eu-west-2.amazonaws.com")
               .with(body: expected_query_body,
                     headers: {
                       "X-Amz-Target" => "DynamoDB_20120810.Scan",
                     })
               .to_return(status: 200, body: query_response)
      end

      it "returns the UserId" do
        expect(gateway.get_user(sub_id)).to eq(user_id)
      end
    end

    context "when the user does not exist" do
      let(:expected_query_body) do
        {
          "FilterExpression":
            "OneLoginSub = :sub",
          "ExpressionAttributeValues": {
            ":sub": { "S": "missing-sub-id" },
          },
          "TableName": "test_users_table",
        }.to_json
      end

      let(:query_response) do
        {
          "Items" => [],
          "Count" => 0,
        }.to_json
      end

      before do
        WebMock.stub_request(:post, "https://dynamodb.eu-west-2.amazonaws.com")
               .with(body: expected_query_body,
                     headers: {
                       "X-Amz-Target" => "DynamoDB_20120810.Scan",
                     })
               .to_return(status: 200, body: query_response)
      end

      it "returns the UserId" do
        expect(gateway.get_user("missing-sub-id")).to be_nil
      end
    end
  end

  describe "#get_user_token" do
    let(:expected_query_body) do
      {
        "Key": {
          "UserId": { "S": user_id },
        },
        "TableName": "test_users_table",
      }.to_json
    end

    context "when getting a token" do
      let(:query_response) do
        {
          "Item" => {
            "UserId" => { "S" => user_id },
            "OneLoginSub" => { "S" => sub_id },
            "CreatedAt" => { "S" => Time.now.to_s },
            "BearerToken" => { "S" => "the-bearer-token" },
          },
        }.to_json
      end

      before do
        WebMock.stub_request(:post, "https://dynamodb.eu-west-2.amazonaws.com")
               .with(body: expected_query_body,
                     headers: {
                       "X-Amz-Target" => "DynamoDB_20120810.GetItem",
                     })
               .to_return(status: 200, body: query_response)
      end

      it "returns the BearerToken" do
        expect(gateway.get_user_token(user_id)).to eq("the-bearer-token")
      end
    end

    context "when the token is missing" do
      it "raises Errors::BearerTokenMissing if the token is missing" do
        WebMock.stub_request(:post, "https://dynamodb.eu-west-2.amazonaws.com")
               .with(body: expected_query_body,
                     headers: {
                       "X-Amz-Target" => "DynamoDB_20120810.GetItem",
                     })
               .to_return(status: 200, body: {}.to_json)

        expect {
          gateway.get_user_token(user_id)
        }.to raise_error(Errors::BearerTokenMissing)
      end
    end
  end

  describe "#get_user_info" do
    let(:expected_query_body) do
      {
        "Key": {
          "UserId": { "S": user_id },
        },
        "TableName": "test_users_table",
      }.to_json
    end

    context "when getting user info for an opted-out user" do
      let(:query_response) do
        {
          "Item" => {
            "UserId" => { "S" => user_id },
            "OneLoginSub" => { "S" => sub_id },
            "CreatedAt" => { "S" => Time.now.to_s },
            "BearerToken" => { "S" => "the-bearer-token" },
            "OptOut" => { "BOOL" => true },
          },
        }.to_json
      end

      before do
        WebMock.stub_request(:post, "https://dynamodb.eu-west-2.amazonaws.com")
               .with(body: expected_query_body,
                     headers: {
                       "X-Amz-Target" => "DynamoDB_20120810.GetItem",
                     })
               .to_return(status: 200, body: query_response)
      end

      it "returns the BearerToken and OptOut info" do
        expect(gateway.get_user_info(user_id)).to eq({ bearer_token: "the-bearer-token", opt_out: true })
      end
    end

    context "when getting user info for a user missing opt-out value" do
      let(:query_response_no_opt_out) do
        {
          "Item" => {
            "UserId" => { "S" => user_id },
            "OneLoginSub" => { "S" => sub_id },
            "CreatedAt" => { "S" => Time.now.to_s },
            "BearerToken" => { "S" => "the-bearer-token" },
          },
        }.to_json
      end

      before do
        WebMock.stub_request(:post, "https://dynamodb.eu-west-2.amazonaws.com")
               .with(body: expected_query_body,
                     headers: {
                       "X-Amz-Target" => "DynamoDB_20120810.GetItem",
                     })
               .to_return(status: 200, body: query_response_no_opt_out)
      end

      it "returns the BearerToken and expected OptOut info" do
        expect(gateway.get_user_info(user_id)).to eq({ bearer_token: "the-bearer-token", opt_out: false })
      end
    end

    context "when the user is missing" do
      before do
        WebMock.stub_request(:post, "https://dynamodb.eu-west-2.amazonaws.com")
               .with(body: expected_query_body,
                     headers: {
                       "X-Amz-Target" => "DynamoDB_20120810.GetItem",
                     })
               .to_return(status: 200, body: {}.to_json)
      end

      it "raises Errors::UserMissing" do
        expect {
          gateway.get_user_info(user_id)
        }.to raise_error(Errors::UserMissing)
      end
    end

    context "when the passed user_id is nil" do
      it "raises Errors::UserMissing" do
        expect {
          gateway.get_user_info(nil)
        }.to raise_error(Errors::UserMissing)
      end
    end
  end

  describe "#toggle_user_opt_out" do
    let(:expected_query_body) do
      {
        "Key": {
          "UserId": { "S": user_id },
        },
        "TableName": "test_users_table",
      }.to_json
    end

    before do
      WebMock.stub_request(:post, "https://dynamodb.eu-west-2.amazonaws.com")
             .with(body: expected_put_item_body,
                   headers: {
                     "X-Amz-Target" => "DynamoDB_20120810.PutItem",
                   })
             .to_return(status: 200, body: "{}")
      WebMock.stub_request(:post, "https://dynamodb.eu-west-2.amazonaws.com")
                     .with(body: expected_query_body,
                           headers: {
                             "X-Amz-Target" => "DynamoDB_20120810.GetItem",
                           })
                     .to_return(status: 200, body: query_response)
    end

    context "when toggling user opt-out value for an opted-out user" do
      let(:query_response) do
        {
          "Item" => {
            "UserId" => { "S" => "user_id" },
            "OneLoginSub" => { "S" => "sub_abcdef123" },
            "BearerToken" => { "S" => "token123" },
            "CreatedAt" => { "S" => "2025-03-05T11:00:00Z" },
            "EmailAddress" => { "S" => "encrypted_email" },
            "OptOut" => { "BOOL" => true },
          },
        }.to_json
      end

      let(:expected_put_item_body) do
        {
          "Item" => {
            "UserId" => { "S" => "user_id" },
            "OneLoginSub" => { "S" => "sub_abcdef123" },
            "BearerToken" => { "S" => "token123" },
            "CreatedAt" => { "S" => "2025-03-05T11:00:00Z" },
            "EmailAddress" => { "S" => "encrypted_email" },
            "OptOut" => { "BOOL": false },
          },
          "TableName" => ENV["EPB_DATA_USER_CREDENTIAL_TABLE_NAME"] || "test_users_table",
        }.to_json
      end

      it "updates the user opt-out value with false" do
        gateway.toggle_user_opt_out(user_id)
        expect(WebMock).to have_requested(:post, "https://dynamodb.eu-west-2.amazonaws.com/")
          .with(
            body: expected_put_item_body,
            headers: { "X-Amz-Target" => "DynamoDB_20120810.PutItem" },
          )
      end
    end

    context "when toggling user opt-out value for an opted-in user" do
      let(:query_response) do
        {
          "Item" => {
            "UserId" => { "S" => "user_id" },
            "OneLoginSub" => { "S" => "sub_abcdef123" },
            "BearerToken" => { "S" => "token123" },
            "CreatedAt" => { "S" => "2025-03-05T11:00:00Z" },
            "EmailAddress" => { "S" => "encrypted_email" },
            "OptOut" => { "BOOL" => false },
          },
        }.to_json
      end

      let(:expected_put_item_body) do
        {
          "Item" => {
            "UserId" => { "S" => "user_id" },
            "OneLoginSub" => { "S" => "sub_abcdef123" },
            "BearerToken" => { "S" => "token123" },
            "CreatedAt" => { "S" => "2025-03-05T11:00:00Z" },
            "EmailAddress" => { "S" => "encrypted_email" },
            "OptOut" => { "BOOL": true },
          },
          "TableName" => ENV["EPB_DATA_USER_CREDENTIAL_TABLE_NAME"] || "test_users_table",
        }.to_json
      end

      it "updates the user opt-out value with true" do
        gateway.toggle_user_opt_out(user_id)
        expect(WebMock).to have_requested(:post, "https://dynamodb.eu-west-2.amazonaws.com/")
                             .with(
                               body: expected_put_item_body,
                               headers: { "X-Amz-Target" => "DynamoDB_20120810.PutItem" },
                             )
      end
    end
  end

  describe "#get_opt_in_users" do
    let(:query_response) do
      {
        "Items" => [
          {
            "UserId" => { "S" => user_id },
            "OneLoginSub" => { "S" => sub_id },
            "CreatedAt" => { "S" => Time.now.to_s },
            "EmailAddress" => { "S" => "encrypted_email_1" },
            "OptOut" => { "BOOL" => false },
            "BearerToken" => { "S" => "the-bearer-token" },
          },
          {
            "UserId" => { "S" => user_id },
            "OneLoginSub" => { "S" => sub_id },
            "CreatedAt" => { "S" => Time.now.to_s },
            "EmailAddress" => { "S" => "encrypted_email_2" },
            "OptOut" => { "BOOL" => false },
            "BearerToken" => { "S" => "the-bearer-token" },
          },
        ],
        "Count" => 2,
      }.to_json
    end

    before do
      stub_request(:post, "https://dynamodb.eu-west-2.amazonaws.com/")
        .with(
          headers: {
            "Host" => "dynamodb.eu-west-2.amazonaws.com",
            "X-Amz-Target" => "DynamoDB_20120810.Scan",
          },
        )
        .to_return(status: 200, body: query_response, headers: {})
      allow(kms_gateway).to receive(:decrypt).with("encrypted_email_1").and_return("test@email.com")
      allow(kms_gateway).to receive(:decrypt).with("encrypted_email_2").and_return("name.test@email.com")
    end

    it "returns data for user who have not opted out" do
      expect(gateway.get_opt_in_users).to eq %w[test@email.com name.test@email.com]
    end

    context "when a email cannot be decrypted" do
      let(:query_response) do
        {
          "Items" => [
            {
              "UserId" => { "S" => user_id },
              "OneLoginSub" => { "S" => sub_id },
              "CreatedAt" => { "S" => Time.now.to_s },
              "EmailAddress" => { "S" => "encrypted_email_1" },
              "OptOut" => { "BOOL" => false },
              "BearerToken" => { "S" => "the-bearer-token" },
            },
            {
              "UserId" => { "S" => user_id },
              "OneLoginSub" => { "S" => sub_id },
              "CreatedAt" => { "S" => Time.now.to_s },
              "EmailAddress" => { "S" => "bad_data" },
              "OptOut" => { "BOOL" => false },
              "BearerToken" => { "S" => "the-bearer-token" },
            },

            {
              "UserId" => { "S" => user_id },
              "OneLoginSub" => { "S" => sub_id },
              "CreatedAt" => { "S" => Time.now.to_s },
              "EmailAddress" => { "S" => "encrypted_email_2" },
              "OptOut" => { "BOOL" => false },
              "BearerToken" => { "S" => "the-bearer-token" },
            },
          ],
          "Count" => 1,
        }.to_json
      end

      before do
        stub_request(:post, "https://dynamodb.eu-west-2.amazonaws.com/")
          .with(
            headers: {
              "Host" => "dynamodb.eu-west-2.amazonaws.com",
              "X-Amz-Target" => "DynamoDB_20120810.Scan",
            },
          )
          .to_return(status: 200, body: query_response, headers: {})
        allow(kms_gateway).to receive(:decrypt).with("encrypted_email_1").and_return("test@email.com")
        allow(kms_gateway).to receive(:decrypt).with("encrypted_email_2").and_return("name.test@email.com")

        allow(kms_gateway).to receive(:decrypt).with("bad_data").and_raise Errors::KmsDecryptionError
      end

      it "returns the 2 emails that have been decrypted" do
        expect(gateway.get_opt_in_users).to eq %w[test@email.com name.test@email.com]
      end
    end

    context "when an email missing from the items" do
      let(:query_response) do
        {
          "Items" => [
            {
              "UserId" => { "S" => user_id },
              "OneLoginSub" => { "S" => sub_id },
              "CreatedAt" => { "S" => Time.now.to_s },
              "EmailAddress" => { "S" => "encrypted_email_1" },
              "OptOut" => { "BOOL" => false },
              "BearerToken" => { "S" => "the-bearer-token" },
            },
            {
              "UserId" => { "S" => user_id },
              "OneLoginSub" => { "S" => sub_id },
              "CreatedAt" => { "S" => Time.now.to_s },
              "OptOut" => { "BOOL" => false },
              "BearerToken" => { "S" => "the-bearer-token" },
            },
            {
              "UserId" => { "S" => user_id },
              "OneLoginSub" => { "S" => sub_id },
              "CreatedAt" => { "S" => Time.now.to_s },
              "EmailAddress" => { "S" => "encrypted_email_2" },
              "OptOut" => { "BOOL" => false },
              "BearerToken" => { "S" => "the-bearer-token" },
            },
          ],
          "Count" => 3,
        }.to_json
      end

      before do
        stub_request(:post, "https://dynamodb.eu-west-2.amazonaws.com/")
          .with(
            headers: {
              "Host" => "dynamodb.eu-west-2.amazonaws.com",
              "X-Amz-Target" => "DynamoDB_20120810.Scan",
            },
          )
          .to_return(status: 200, body: query_response, headers: {})
      end

      it "returns the emails" do
        expect(gateway.get_opt_in_users).to eq %w[test@email.com name.test@email.com]
      end
    end
  end
end

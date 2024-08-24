require 'aws-record'
require 'aws-sdk-dynamodb'

dynamo_db_client = Aws::DynamoDB::Client.new(
  region: "localhost",
  endpoint: "http://localhost:8000",
  credentials: Aws::Credentials.new('foo', 'bar')
)

CivilServiceJobsScraper::DynamoDbResultStore.configure_client(dynamo_db_client)
CivilServiceJobsScraper::DynamoDbResultStore.ensure_table_exists!

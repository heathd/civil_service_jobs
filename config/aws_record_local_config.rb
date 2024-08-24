CivilServiceJobsScraper::DynamoDbResultStore::JobRecord.configure_client(
  region: "localhost",
  access_key_id: "foo",
  secret_access_key: "bar",
  endpoint: "http://localhost:8000"
)
CivilServiceJobsScraper::DynamoDbResultStore.ensure_table_exists!

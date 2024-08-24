RSpec.describe CivilServiceJobsScraper::DynamoDbResultStore do
  before(:all) do
    @db = DynamoDb.new(in_memory: true)
    @db.start
    # Dynamoid::Tasks::Database.create_tables
  end

  before(:each) do
    begin
      CivilServiceJobsScraper::DynamoDbResultStore::Job.configure_client(
        region: "localhost",
        access_key_id: "foo",
        secret_access_key: "bar",
        endpoint: "http://localhost:8000"
      )
      CivilServiceJobsScraper::DynamoDbResultStore.ensure_table_exists!
      CivilServiceJobsScraper::DynamoDbResultStore.delete_all!
    rescue Aws::DynamoDB::Errors::ResourceNotFoundException
    end
  end

  subject(:rs) { described_class.new }
  it "can create a job with a given refcode" do
    rs.add({"refcode"=> "foo"})
    all = rs.each.to_a
    expect(all.size).to eq(1)
    expect(all[0].refcode).to eq("foo")
  end

  it "updates a job if added twice" do
    rs.add({"refcode"=> "foo", "title"=> "Small Cheese"})
    rs.add({"refcode"=> "foo", "title"=> "Big Cheese"})
    all = rs.each.to_a
    expect(all.size).to eq(1)
    expect(all.first.title).to eq("Big Cheese")
  end

  it "Doesn't have test interference" do
    all = rs.each.to_a
    expect(all.size).to eq(0)
  end

  it "stores extra attributes of a job outside of the core fields" do
    rs.add("refcode"=> "foo", "title"=> "Small Cheese", "extra_field" => "value")
    expect(rs.find("foo").extra_fields).to eq({"extra_field" => "value"})
  end

  after(:all) do
    @db.stop
  end
end

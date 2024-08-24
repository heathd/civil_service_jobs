RSpec.describe CivilServiceJobsScraper::DynamoDbResultStore do
  before(:all) do
    @db = DynamoDb.new(in_memory: true)
    @db.start
    # Dynamoid::Tasks::Database.create_tables
  end

  before(:each) do
    begin
      dynamo_db_client = Aws::DynamoDB::Client.new(
        region: "localhost",
        endpoint: "http://localhost:#{@db.port}",
        credentials: Aws::Credentials.new('foo', 'bar')
      )

      CivilServiceJobsScraper::DynamoDbResultStore.configure_client(dynamo_db_client)
      CivilServiceJobsScraper::DynamoDbResultStore.ensure_table_exists!
      CivilServiceJobsScraper::DynamoDbResultStore.delete_all!
    rescue Aws::DynamoDB::Errors::ResourceNotFoundException
    end
  end

  subject(:rs) { described_class.new }
  it "can create a job with a given refcode" do
    job = CivilServiceJobsScraper::Model::Job.new({"refcode"=> "foo"})
    rs.add(job)
    all = rs.each.to_a
    expect(all.size).to eq(1)
    expect(all[0].refcode).to eq("foo")
  end

  it "updates a job if added twice" do
    job1 = CivilServiceJobsScraper::Model::Job.new({"refcode"=> "foo", "title"=> "Small Cheese"})
    job2 = CivilServiceJobsScraper::Model::Job.new({"refcode"=> "foo", "title"=> "Big Cheese"})

    rs.add(job1)
    rs.add(job2)
    all = rs.each.to_a
    expect(all.size).to eq(1)
    expect(all.first.title).to eq("Big Cheese")
  end

  it "Doesn't have test interference" do
    all = rs.each.to_a
    expect(all.size).to eq(0)
  end

  it "stores extra attributes of a job outside of the core fields" do
    job = CivilServiceJobsScraper::Model::Job.new("refcode"=> "foo", "title"=> "Small Cheese", "extra_field" => "value")
    rs.add(job)
    expect(rs.find("foo").extra_fields).to eq({"extra_field" => "value"})
  end

  after(:all) do
    @db.stop
  end
end

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

  it "supports exists?" do
    unsaved_job = CivilServiceJobsScraper::Model::Job.new({"refcode"=> "bob", "title"=> "Big Cheese"})
    saved_job = CivilServiceJobsScraper::Model::Job.new({"refcode"=> "foo", "title"=> "Small Cheese"})
    rs.add(saved_job)

    expect(rs.exists?(saved_job)).to eq(true)
    expect(rs.exists?(unsaved_job)).to eq(false)
  end

  it "should_skip? is always false if no limit is specified" do
    result_store = described_class.new()
    job = CivilServiceJobsScraper::Model::Job.new({"refcode"=> "bob", "title"=> "Big Cheese"})
    expect(result_store.should_skip?(job)).to eq(false)
    result_store.add(job)
    expect(result_store.should_skip?(job)).to eq(false)
  end

  it "should_skip? is true if limit reached" do
    result_store = described_class.new(limit: 1)
    job = CivilServiceJobsScraper::Model::Job.new({"refcode"=> "bob", "title"=> "Big Cheese"})
    expect(result_store.should_skip?(job)).to eq(false)
    result_store.add(job)
    expect(result_store.should_skip?(job)).to eq(true)
  end

  it "Doesn't have test interference" do
    all = rs.each.to_a
    expect(all.size).to eq(0)
  end

  it "stores extra attributes of a job outside of the core fields" do
    job = CivilServiceJobsScraper::Model::Job.new(
      "refcode"=> "foo",
      "title"=> "Small Cheese",
      "extra_field" => "value"
    )
    rs.add(job)
    expect(rs.find("foo").attribute(:extra_field)).to eq("value")
  end

  it "can store an activity record" do
    a = CivilServiceJobsScraper::DynamoDbResultStore::ActivityRecord.new(operation: "Foo")
    a.save!

    all = CivilServiceJobsScraper::DynamoDbResultStore::ActivityRecord.scan()
    expect(all.count).to eq(1)
    expect(all.first.operation).to eq("Foo")
    expect(all.first.id).to match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/)
  end

  it "can find an activity record by type" do
    ActivityRecord = CivilServiceJobsScraper::DynamoDbResultStore::ActivityRecord

    a1 = ActivityRecord.new(operation: "Start")
    a2 = ActivityRecord.new(operation: "Stop")
    [a1, a2].each(&:save!)

    all = ActivityRecord.scan()
    expect(all.count).to eq(2)

    stop_operations = ActivityRecord.find_by_operation("Stop")
    expect(stop_operations.map(&:operation)).to eq(%w{Stop})
    expect(stop_operations.map(&:id)).to eq([a2.id])
  end

  it "can say if an activity has ever been executed" do
    ActivityRecord = CivilServiceJobsScraper::DynamoDbResultStore::ActivityRecord

    ActivityRecord.new(operation: "Start").save!

    expect(ActivityRecord.operation_never_run?("Stop")).to eq(true)
    expect(ActivityRecord.operation_never_run?("Start")).to eq(false)
  end

  after(:all) do
    @db.stop
  end
end

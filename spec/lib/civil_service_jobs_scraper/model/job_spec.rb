RSpec.describe CivilServiceJobsScraper::Model::Job do
  it "can be built from sqlite hash" do
    job = described_class.from_sqlite_record(
      "refcode" => "Reference : 318100",
      "title" => "Big Cheese"
    )
    expect(job.refcode).to eq("318100")
    expect(job.attributes).to eq(
      "refcode" => "318100",
      "title" => "Big Cheese"
    )
  end
end

require 'mechanize'

RSpec.describe CivilServiceJobsScraper::Page::JobTeaser do
	let(:agent) { Mechanize.new }
	let(:spec_path) { Pathname.new(File.dirname(__FILE__)) + "../../fixtures" }
	let(:fixture_file_uri) { "file://" + (spec_path + "result_page1.html").to_s }
	let(:page) { agent.get(fixture_file_uri) }
	let(:status_display) { instance_double(CivilServiceJobsScraper::StatusDisplay) }
	let(:result_page) { CivilServiceJobsScraper::Page::ResultPage.new(page, status_display: status_display) }
	subject(:job_teaser) { result_page.job_list.first }

	it "has a refcode" do
		expect(job_teaser.refcode).to eq("Reference : 296730")
	end
	
	it "has a title" do
		expect(job_teaser.title).to eq("Head of Policy Research")
	end

	it "has a job_page_url" do
		expect(job_teaser.job_page_url).to eq("https://www.civilservicejobs.service.gov.uk/csr/index.cgi?SID=c2VhcmNocGFnZT0xJm93bmVydHlwZT1mYWlyJnVzZXJzZWFyY2hjb250ZXh0PTQxMTc3ODU0JmpvYmxpc3Rfdmlld192YWM9MTg2MjM0OCZzZWFyY2hzb3J0PWNsb3NpbmcmcGFnZWFjdGlvbj12aWV3dmFjYnlqb2JsaXN0JnBhZ2VjbGFzcz1Kb2JzJm93bmVyPTUwNzAwMDAmcmVxc2lnPTE2ODgzMTY3NTItNjI1YjgxOTMxZjhmZWI5ZjVmMDBlYTIwZGMyNmIyZDcwYjA2ZWIyZg==")
	end

	it "has fields" do
		expect(job_teaser.fields).to eq({
       closingdate: "Closes : 10:00 pm on Sunday 2nd July 2023",
       department: "House of Lords",
       grade: "",
       location: "Westminster\n",
       refcode: "Reference : 296730",
       salary: "Salary : £53,730",
       stage: "",
       title: "Head of Policy Research",
		})
	end

end
require 'mechanize'
require 'pathname'

RSpec.describe CivilServiceJobsScraper::Page::ResultPage do
	let(:agent) { Mechanize.new }
	let(:spec_path) { Pathname.new(File.dirname(__FILE__)) + "../../fixtures" }
	let(:fixture_file_uri) { "file://" + (spec_path + "result_page1.html").to_s }
	let(:page) { agent.get(fixture_file_uri) }
	let(:status_display) { instance_double(CivilServiceJobsScraper::StatusDisplay) }
	subject(:result_page) { CivilServiceJobsScraper::Page::ResultPage.new(page, status_display: status_display) }
	
	it "identifies the last page by scraping the pagination indicator" do
		expect(result_page.last_page).to eq(95)
	end

	it "identifies the current page by scraping the pagination indicator" do
		expect(result_page.current_page).to eq(1)
	end

	it "has a next page" do
		expect(result_page.next_page?).to be_truthy
	end

	it "extracts the next page url" do
		expect(result_page.next_page_url).to eq("https://www.civilservicejobs.service.gov.uk/csr/index.cgi?SID=cGFnZT0yJmNvbnRleHRpZD00MTE3Nzg1NCZwYWdlY2xhc3M9U2VhcmNoJm93bmVydHlwZT1mYWlyJnBhZ2VhY3Rpb249c2VhcmNoY29udGV4dCZvd25lcj01MDcwMDAwJnNvcnQ9Y2xvc2luZyZyZXFzaWc9MTY4ODMxNjc1Mi02MjViODE5MzFmOGZlYjlmNWYwMGVhMjBkYzI2YjJkNzBiMDZlYjJm")
	end

	describe "#job_list" do
		it "extracts a list of 25 items" do
			expect(result_page.job_list.size).to eq(25)
		end

		it "extracts JobTeaser items" do
			expect(result_page.job_list.first).to be_instance_of(CivilServiceJobsScraper::Page::JobTeaser)
		end
	end
end
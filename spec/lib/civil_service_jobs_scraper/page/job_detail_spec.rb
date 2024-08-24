require 'mechanize'

RSpec.describe CivilServiceJobsScraper::Page::JobDetail do
	let(:agent) { Mechanize.new }
	let(:spec_path) { Pathname.new(File.dirname(__FILE__)) + "../../../fixtures" }
	let(:fixture_file_uri) { "file://" + (spec_path + "job_detail_page.html").to_s }
	let(:page) { agent.get(fixture_file_uri) }
	let(:status_display) { instance_double(CivilServiceJobsScraper::TtyStatusDisplay) }
	subject(:job_detail) { CivilServiceJobsScraper::Page::JobDetail.new(page) }

	it "extracts side panel fields" do
		expect(job_detail.side_panel_fields).to eq({
			business_area: "Committee",
			contract_type: "Fixed Term",
			job_grade_0: "Other",
      job_grade_1: "HL8",
      length_of_employment: "Two years, with the possibility of extension or permanence",
      number_of_jobs_available: "1",
      reference_number: "296730",
			salary: "£53,730",
			type_of_role: "Policy",
			working_pattern: "Full-time"
		})
	end

	it "extracts body" do
		expect(job_detail.body).to match("<li>Significant experience of and expertise in undertaking high quality analysis on public policy matters.</li>")
	end
end

#typed: true

require 'date'
require 'time'
require 'tzinfo'

class GoogleDrive::SpreadsheetRow
  sig {returns(CivilServiceJobsScraper::DynamoDbResultStore::JobMainRecord)}
  attr_reader :job

  sig {returns(T.nilable(CivilServiceJobsScraper::DynamoDbResultStore::JobBodyRecord))}
  attr_reader :body

  sig {returns(TZInfo::Timezone)}
  attr_reader :tz

  sig {params(
    job: CivilServiceJobsScraper::DynamoDbResultStore::JobMainRecord,
    body: T.nilable(CivilServiceJobsScraper::DynamoDbResultStore::JobBodyRecord)
    ).void}
  def initialize(job, body)
    @job = job
    @body = body
    @tz = TZInfo::Timezone.get("Europe/London")
  end

  sig {returns(T::Array[String])}
  def row
    @row ||= [
      generate_google_datetime(tz.to_local(job.created_at)),
      tz.to_local(job.created_at).strftime('%Z'),
      job.refcode,
      job.title,
      job.department,
      job.location,
      job.salary,
      closedate(job.closingdate),
      job.grade,
      job.stage,
      job.reference_number,
      job.job_grade,
      job.number_of_jobs_available,
      job.job_grade_0,
      job.job_grade_1,
      job.contract_type,
      job.business_area,
      job.type_of_role,
      job.working_pattern,
      job.length_of_employment,
      html_to_markdown(body && body.body)
    ]
  end

  sig {params(n: BatchSheet).returns(T::Array[String])}
  def for_refcode_sheet(n)
    (row[0..7] || []) + [n.name]
  end

  def approximate_size_in_bytes
    row.map do |v|
      v.to_s.size
    end.sum
  end

  sig {returns(T::Array[String])}
  def header_row
    [
			"Scrape Date",
			"Scrape TZ",
			"Refcode",
			"Job title",
			"Department",
			"Location",
			"Salary",
			"Closing date",
			"Grade",
			"Stage",
			"Reference Number",
			"Job Grade",
			"Number Of Jobs Available",
			"Job Grade 0",
			"Job Grade 1",
			"Contract Type",
			"Business Area",
			"Type Of Role",
			"Working Pattern",
			"Length Of Employment",
			"Body"
		]
  end

private
  sig {params(html: T.nilable(String)).returns(String)}
  def html_to_markdown(html)
    ReverseMarkdown.convert(html || "")
  end

  def closedate(job_closing_statement)
    if job_closing_statement =~ /Closes : (.*?) on (.*?)$/
      time = Time.parse($1) rescue Time.new(23,55,00)
      date = Date.parse($2)

      generate_google_datetime(tz.local_datetime(date.year,date.month,date.day,time.hour,time.min,time.sec))
    else
      job_closing_statement
    end

  rescue
    job_closing_statement
  end

  sig{params(datetime: TZInfo::DateTimeWithOffset).returns(Numeric)}
  def generate_google_datetime(datetime)
    #	The integer part represents the number of days since December 30, 1899. For example, 1 represents December 31, 1899, 2 represents January 1, 1900, and so on.
    #	The fractional part represents the fraction of the day. For example, 0.5 represents 12:00 PM (noon), 0.75 represents 6:00 PM, and so on.
    reference_date = Date.new(1899,12,30)
    integer_part = datetime.to_date - reference_date

    fractional_part = datetime.hour/24r + datetime.minute/(24*60r) + datetime.second/(24*60*60r)

    (integer_part + fractional_part).to_f
  end
end

# typed: true
# require 'dynamoid'
require "aws-record"
require 'date'
require 'time'
require 'securerandom'

class CivilServiceJobsScraper::DynamoDbResultStore
  extend T::Sig

  class ActivityRecord
    include Aws::Record

    set_table_name "activity"

    string_attr :id, hash_key: true, default_value: lambda { SecureRandom.uuid }
    datetime_attr :created_at, default_value: lambda { DateTime.now }
    string_attr :operation
    string_attr :message

    def self.find_by_operation(operation_value)
      # Use scan method to filter items by the operation attribute
      self.scan(
        filter_expression: "operation = :operation_val",
        expression_attribute_values: {
          ":operation_val" => operation_value
        }
      )
    end
  end

  class JobRecord
    include Aws::Record

    set_table_name "jobs"

    string_attr :refcode, hash_key: true
    string_attr :title
    string_attr :department
    string_attr :location
    string_attr :salary
    string_attr :closingdate
    string_attr :grade
    string_attr :stage
    string_attr :reference_number
    string_attr :job_grade
    string_attr :contract_type
    string_attr :business_area
    string_attr :type_of_role
    string_attr :working_pattern
    string_attr :number_of_jobs_available
    string_attr :body
    string_attr :job_grade_0
    string_attr :job_grade_1
    string_attr :length_of_employment
    datetime_attr :created_at, default_value: lambda { DateTime.now }
    map_attr :extra_fields
  end

  def self.configure_client(client)
    CivilServiceJobsScraper::DynamoDbResultStore::JobRecord.configure_client(client: client)
    CivilServiceJobsScraper::DynamoDbResultStore::ActivityRecord.configure_client(client: client)
  end

  def self.ensure_table_exists!
    Aws::Record::TableMigration.new(CivilServiceJobsScraper::DynamoDbResultStore::ActivityRecord).create!({
      billing_mode: "PAY_PER_REQUEST"
    }) unless ActivityRecord.table_exists?

    Aws::Record::TableMigration.new(CivilServiceJobsScraper::DynamoDbResultStore::JobRecord).create!({
      billing_mode: "PAY_PER_REQUEST"
    }) unless JobRecord.table_exists?
  end

  def self.delete_all!
    delete_jobs!
    delete_activity_records!
  end

  def self.delete_activity_records!
    all_activity_records = ActivityRecord.scan()
    return if all_activity_records.empty?

    operation = Aws::Record::Batch.write(client: ActivityRecord.dynamodb_client) do |db|
      all_activity_records.each do |r|
        db.delete(r)
      end
    end

    # unprocessed items can be retried by calling Aws::Record::BatchWrite#execute!
    operation.execute! until operation.complete?
  end

  def self.delete_jobs!
    all_jobs = JobRecord.scan(projection_expression: "refcode")
    return if all_jobs.empty?

    operation = Aws::Record::Batch.write(client: JobRecord.dynamodb_client) do |db|
      all_jobs.each do |job|
        db.delete(job)
      end
    end

    # unprocessed items can be retried by calling Aws::Record::BatchWrite#execute!
    operation.execute! until operation.complete?

  end

  sig {params(job: CivilServiceJobsScraper::Model::Job).void}
  def add(job)
    job_record = begin
      JobRecord.find(refcode: job.refcode)
    rescue Aws::DynamoDB::Errors::ResourceNotFoundException
      # ,
      #     Dynamoid::Errors::RecordNotFound
      # # couldn't perform #find because the table doesn't exist yet
      # OR table exists but record not found
      nil
    end

    normalised_attributes = normalise_attributes(job)
    if job_record
      job_record.update!(**normalised_attributes)
    else
      job_record = JobRecord.new(**normalised_attributes)
      job_record.save!
    end
  end

  sig {params(job: CivilServiceJobsScraper::Model::Job).returns(T::Hash[String, T.any(String, T::Hash[String, String])])}
  def normalise_attributes(job)
    normal_attrs = JobRecord.attributes.attributes.keys - [:extra_fields]
    normalised = {}
    job.attributes.each do |k,v|
      if normal_attrs.include?(k.to_sym)
        normalised[k] = v
      else
        normalised[:extra_fields] ||= {}
        normalised[:extra_fields][k] = v
      end
    end
    normalised
  end

  sig {params(refcode: String).returns(JobRecord)}
  def find(refcode)
    JobRecord.find(refcode: refcode)
  end

  sig {params(block: T.nilable(T.proc.params(arg0: JobRecord).void)).returns(Enumerable)}
  def each(&block)
    JobRecord.scan.each(&block)
  end
end

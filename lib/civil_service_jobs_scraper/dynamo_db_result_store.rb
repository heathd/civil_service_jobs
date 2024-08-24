# require 'dynamoid'
require "aws-record"

class CivilServiceJobsScraper::DynamoDbResultStore
  class Job
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
    map_attr :extra_fields
  end

  def self.ensure_table_exists!
    return if Job.table_exists?
    Aws::Record::TableMigration.new(CivilServiceJobsScraper::DynamoDbResultStore::Job).create!({
      billing_mode: "PAY_PER_REQUEST"
    })
  end

  def self.delete_all!
    all_jobs = Job.scan(projection_expression: "refcode")
    return if all_jobs.empty?

    operation = Aws::Record::Batch.write(client: Job.dynamodb_client) do |db|
      all_jobs.each do |job|
        db.delete(job)
      end
    end

    # unprocessed items can be retried by calling Aws::Record::BatchWrite#execute!
    operation.execute! until operation.complete?

  end

  def add(attributes)
    refcode = attributes["refcode"]
    job = begin
      Job.find(refcode: refcode)
    rescue Aws::DynamoDB::Errors::ResourceNotFoundException
      # ,
      #     Dynamoid::Errors::RecordNotFound
      # # couldn't perform #find because the table doesn't exist yet
      # OR table exists but record not found
      nil
    end

    normalised_attributes = normalise_attributes(attributes)
    if job
      job.update!(**normalised_attributes)
    else
      job = Job.new(**normalised_attributes)
      job.save!
    end
  end

  def normalise_attributes(attributes)
    normal_attrs = Job.attributes.attributes.keys - [:extra_fields]
    normalised = {}
    attributes.each do |k,v|
      if normal_attrs.include?(k.to_sym)
        normalised[k] = v
      else
        normalised[:extra_fields] ||= {}
        normalised[:extra_fields][k] = v
      end
    end
    normalised
  end

  def find(refcode)
    Job.find(refcode: refcode)
  end

  def each(&block)
    Job.scan.each(&block)
  end
end

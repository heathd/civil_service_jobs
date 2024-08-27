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

    set_table_name "civil_service_jobs_activity"

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

    def self.operation_never_run?(operation)
      find_by_operation(operation).empty?
    end
  end

  class JobRecordBase
    include Aws::Record

    set_table_name "civil_service_jobs"

    string_attr :refcode, hash_key: true
    string_attr :record_type, range_key: true
  end

  class JobMainRecord < JobRecordBase
    include Aws::Record

    RECORD_TYPE = "Main"

    string_attr :title
    string_attr :department
    string_attr :location
    string_attr :salary
    string_attr :closingdate
    string_attr :grade
    string_attr :stage
    string_attr :reference_number
    string_attr :job_grade
    string_attr :number_of_jobs_available
    string_attr :job_grade_0
    string_attr :job_grade_1

    string_attr :contract_type
    string_attr :business_area
    string_attr :type_of_role
    string_attr :working_pattern
    string_attr :length_of_employment
    datetime_attr :created_at, default_value: lambda { DateTime.now }

    def body_record
      JobBodyRecord.find(refcode: self.refcode, record_type: JobBodyRecord::RECORD_TYPE)
    end
  end


  class JobBodyRecord < JobRecordBase
    include Aws::Record
    RECORD_TYPE = "Body"

    string_attr :body
  end

  class JobExtraFieldsRecord < JobRecordBase
    include Aws::Record

    RECORD_TYPE = "Extra"

    map_attr :extra_fields
  end

  def self.configure_client(client)
    CivilServiceJobsScraper::DynamoDbResultStore::JobRecordBase.configure_client(client: client)
    CivilServiceJobsScraper::DynamoDbResultStore::ActivityRecord.configure_client(client: client)
  end

  def self.ensure_table_exists!
    Aws::Record::TableMigration.new(CivilServiceJobsScraper::DynamoDbResultStore::ActivityRecord).create!({
      billing_mode: "PAY_PER_REQUEST"
    }) unless ActivityRecord.table_exists?

    Aws::Record::TableMigration.new(CivilServiceJobsScraper::DynamoDbResultStore::JobRecordBase).create!({
      billing_mode: "PAY_PER_REQUEST"
    }) unless JobRecordBase.table_exists?
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
    all_jobs = JobRecordBase.scan()
    return if all_jobs.empty?

    operation = Aws::Record::Batch.write(client: JobRecordBase.dynamodb_client) do |db|
      all_jobs.each do |job|
        db.delete(job)
      end
    end

    # unprocessed items can be retried by calling Aws::Record::BatchWrite#execute!
    operation.execute! until operation.complete?

  end

  sig {params(limit: T.nilable(Integer)).void}
  def initialize(limit: nil)
    @limit = limit
    @download_counter = 0
  end

  def all_existing_refcodes
    @all_existing_refcodes ||= JobMainRecord.scan(projection_expression: "refcode").map(&:refcode)
  end

  def job_already_stored?(refcode)
    all_existing_refcodes.include?(refcode)
  end

  sig {params(jobs: T::Array[CivilServiceJobsScraper::Model::Job]).void}
  def add_batch(jobs)
    raise "Too many jobs in batch (#{jobs.size})" if jobs.size > 12
    operation = Aws::Record::Batch.write(client: JobMainRecord.dynamodb_client) do |db|
      jobs.each do |job|
        main_record = JobMainRecord.new(refcode: job.refcode, record_type: JobMainRecord::RECORD_TYPE)
        main_attrs = slice_attributes(job, JobMainRecord.attributes.attributes.keys)
        main_record.assign_attributes(main_attrs)
        db.put(main_record)

        body_record = JobBodyRecord.new(record_type: JobBodyRecord::RECORD_TYPE)
        body_attrs = slice_attributes(job, JobBodyRecord.attributes.attributes.keys)
        body_record.assign_attributes(body_attrs)
        db.put(body_record)
      end
    end

    operation.execute! until operation.complete?
  end


  sig {params(job: CivilServiceJobsScraper::Model::Job).void}
  def add(job)
    @download_counter += 1

    main_record = JobMainRecord.find(refcode: job.refcode, record_type: JobMainRecord::RECORD_TYPE)
    body_record = JobBodyRecord.find(refcode: job.refcode, record_type: JobBodyRecord::RECORD_TYPE) if main_record
    extra_record = JobExtraFieldsRecord.find(refcode: job.refcode, record_type: JobExtraFieldsRecord::RECORD_TYPE) if main_record

    main_record ||= JobMainRecord.new(refcode: job.refcode, record_type: JobMainRecord::RECORD_TYPE)
    main_attrs = slice_attributes(job, JobMainRecord.attributes.attributes.keys)
    main_record.assign_attributes(main_attrs)
    main_record.save!

    body_record ||= JobBodyRecord.new(record_type: JobBodyRecord::RECORD_TYPE)
    body_attrs = slice_attributes(job, JobBodyRecord.attributes.attributes.keys)
    body_record.assign_attributes(body_attrs)
    body_record.save!

    remaining_keys = job.attributes.keys.map(&:to_sym) - main_attrs.keys - body_attrs.keys
    extra_fields = slice_attributes(job, remaining_keys)
    if extra_fields.any?
      extra_record ||= JobExtraFieldsRecord.new(refcode: job.refcode, record_type: JobExtraFieldsRecord::RECORD_TYPE)
      extra_record.extra_fields = extra_fields
      extra_record.save!
    end
  end

  sig {
    params(job: CivilServiceJobsScraper::Model::Job, attribute_keys: T::Array[Symbol])
      .returns(T::Hash[Symbol, String])}
  def slice_attributes(job, attribute_keys)
    attribute_keys.inject({}) do |memo, attr|
      if job.has_attribute?(attr)
        memo.merge(attr => job.attribute(attr))
      else
        memo
      end
    end
  end

  # sig {params(job: CivilServiceJobsScraper::Model::Job).returns(T::Hash[String, T.any(String, T::Hash[String, String])])}
  # def normalise_attributes(job)

  #   normal_attrs = JobRecord.attributes.attributes.keys - [:extra_fields]
  #   normalised = {}
  #   job.attributes.each do |k,v|
  #     if normal_attrs.include?(k.to_sym)
  #       normalised[k] = v
  #     else
  #       normalised[:extra_fields] ||= {}
  #       normalised[:extra_fields][k] = v
  #     end
  #   end
  #   normalised
  # end

  sig {params(refcode: String).returns(CivilServiceJobsScraper::Model::Job)}
  def find(refcode)
    main = JobMainRecord.find(refcode: refcode, record_type: JobMainRecord::RECORD_TYPE)
    body = JobBodyRecord.find(refcode: refcode, record_type: JobBodyRecord::RECORD_TYPE)
    extra = JobExtraFieldsRecord.find(refcode: refcode, record_type: JobExtraFieldsRecord::RECORD_TYPE)
    attrs = T.let(main.to_h, T::Hash[Symbol, String])
    attrs[:body] = body.body if body
    if extra
      extra.extra_fields.each do |k, v|
        attrs[k.to_sym] = v
      end
    end
    CivilServiceJobsScraper::Model::Job.new(attrs)
  end

  sig {params(block: T.nilable(T.proc.params(arg0: JobMainRecord).void)).returns(Enumerator)}
  def each(&block)
    opts = {
      filter_expression: "#T = :record_type",
      expression_attribute_names: {
        "#T" => "record_type",
      },
      expression_attribute_values: {
        ":record_type" => JobMainRecord::RECORD_TYPE
      }
    }
    JobMainRecord.scan(opts).each(&block)
  end

  sig {params(job: CivilServiceJobsScraper::Model::Job).returns(T::Boolean)}
  def exists?(job)
    !JobMainRecord.find(
      refcode: job.refcode,
      record_type: JobMainRecord::RECORD_TYPE
    ).nil?
  end

  sig {params(job: CivilServiceJobsScraper::Model::Job).returns(T::Boolean)}
  def should_skip?(job)
    if @limit.nil?
      false
    else
      @download_counter >= @limit
    end
  end
end

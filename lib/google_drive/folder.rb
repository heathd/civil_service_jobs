#typed: true

require 'googleauth'
require 'google/apis/sheets_v4'
require 'google/apis/drive_v3'

class GoogleDrive::Folder
  attr_reader :folder_id, :authorizer, :logger

  def initialize(folder_id:, authorizer: GoogleDrive::Authorizer.new, logger: Logger.new(nil))
    @authorizer = authorizer
    @folder_id = folder_id
    @logger = logger
  end

  sig {params(spreadsheet_id: String, range: String).returns(T::Array[T::Array[String]])}
  def get_spreadsheet_values(spreadsheet_id, range)
    with_retries { sheets_service.get_spreadsheet_values(spreadsheet_id, range).values } || []
  end

  def count_refcodes_in_sheet(sheet_id)
    values = get_spreadsheet_values(sheet_id, 'Sheet1!C:C')
    if values
      values[1..-1].reject(&:empty?).size
    else
      0
    end
  end

  sig {params(name: String).returns(String)}
  def create_spreadsheet(name)
    created_spreadsheet = sheets_service.create_spreadsheet(
      Google::Apis::SheetsV4::Spreadsheet.new(
        properties: {
          title: name
        }
      )
    )

    add(created_spreadsheet.spreadsheet_id)
    created_spreadsheet.spreadsheet_id
  end

  sig {params(
    spreadsheet_id: String,
    table_range: String,
    rows: T::Array[T::Array[String]]
  ).void}
  def add_data_to_sheet(spreadsheet_id, table_range, rows)
    value_range_object = Google::Apis::SheetsV4::ValueRange.new(
      range: table_range,
      major_dimension: 'ROWS',
      values: rows
    )

    with_retries do
      sheets_service.append_spreadsheet_value(
        spreadsheet_id,
        table_range,
        value_range_object,
        value_input_option: 'RAW'
      )
    end
  end

private
  def with_retries(&block)
    tries = 0

    catch :success do
      begin
        tries += 1
        throw :success, block.call
      rescue Google::Apis::RateLimitError => e
        if tries < 20
          sleep_time = tries^2 / 2
          logger.info "Request was rate limited, sleeping for #{sleep_time} before attempt number #{tries}"
          sleep(sleep_time)
        else
          raise
        end
      end
    end
  end

  def drive_service
    @drive_service ||= begin
      service = Google::Apis::DriveV3::DriveService.new
      service.authorization = @authorizer.authorizer
      service
    end
  end

  def sheets_service
    @sheets_service ||= begin
      service = Google::Apis::SheetsV4::SheetsService.new
      service.authorization = @authorizer.authorizer
      service
    end
  end

  def refcode_spreadsheet_id
    @refcode_spreadsheet_id ||= begin
      found = find_sheets_by_name(folder_id, "Refcodes")
      if found.any?
        found.first
      else
        create_spreadsheet("Refcodes")
      end
    end
  end

  def batch_sheets
    @batch_sheets ||= begin
      found = find_sheets_containing_word_in_name(folder_id, "Batch")
      found.inject({}) do |memo, file|
        memo.merge(
          file.name => BatchSheet.new(id: file.id, rows: count_refcodes_in_sheet(file.id), name: file.name)
        )
      end
    end
  end

  sig {params(folder_id: String, sheet_name: String).returns(T::Array[String])}
  def find_sheets_by_name(folder_id, sheet_name)
    response = with_retries { drive_service.list_files(
      q: "'#{folder_id}' in parents and name = '#{sheet_name}' and mimeType = 'application/vnd.google-apps.spreadsheet'",
      fields: 'files(id, name)'
    ) }
    response.files.map(&:id)
  end

  sig {params(folder_id: String, word: String).returns(T::Array[Google::Apis::DriveV3::File])}
  def find_sheets_containing_word_in_name(folder_id, word)
    response = with_retries { drive_service.list_files(
      q: "'#{folder_id}' in parents and name contains '#{word}' and mimeType = 'application/vnd.google-apps.spreadsheet'",
      fields: 'files(id, name)'
    ) }
    response.files
  end

  sig {returns(BatchSheet)}
  def next_batch_sheet
    found = batch_sheets.find do |name, batch_sheet|
      batch_sheet.rows < max_rows_per_batch_sheet
    end

    if found
      found.last
    else
      name = "Batch #{batch_sheets.size + 1}"
      created = BatchSheet.new(id: create_spreadsheet(name), rows: 0, name: name)
      @batch_sheets[name] = created
      created
    end
  end

  def max_rows_per_batch_sheet
    2000
  end

  sig {params(spreadsheet_id: String).returns(String)}
  def add(spreadsheet_id)
    drive_service.update_file(
      spreadsheet_id,
      add_parents: folder_id,
      fields: 'id, parents'
    )
  end

end

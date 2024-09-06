#typed: true
#
class GoogleDrive::Spreadsheet
  attr_reader :authorizer

  sig {returns(GoogleDrive::Folder)}
  attr_reader :folder

  attr_reader :logger, :rows

  sig {params(folder: GoogleDrive::Folder, logger: Logger).void}
  def initialize(folder:, logger: Logger.new(nil))
    @folder = folder
    @logger = logger
    @rows = []
    @batch_sheets = nil
  end


  def sheets_service
    @sheets_service ||= begin
      service = Google::Apis::SheetsV4::SheetsService.new
      service.authorization = authorizer
      service
    end
  end


  def flush!
    n = folder.next_batch_sheet

    logger.info "Appending #{rows.size} rows to refcode sheet"
    folder.add_data_to_sheet(folder.refcode_spreadsheet_id, 'Sheet1!A1', rows.map {|row| row.for_refcode_sheet(n)})
    logger.info "Successfully appended #{rows.size} rows"

    logger.info "Appending #{rows.size} rows to '#{n.name}' (id='#{n.id}')"

    row_data = []
    if n.rows == 0
      row_data << rows.first.header_row
    end
    row_data += rows.map(&:row)

    flush_data_to_sheet(n.id, 'Sheet1!A1', row_data)
    logger.info "Successfully appended #{rows.size} rows to '#{n.name}' (id='#{n.id}')"
    n.rows += rows.size
    @rows = []
  end

  sig {params(block: T.proc.returns(BasicObject)).returns(BasicObject)}
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

  def set_row_height(spreadsheet_id, pixel_height = 21, sheet_id = "Sheet1")
    # Create the request to update row height
    requests = [
      {
        update_dimension_properties: {
          range: {
            sheet_id: sheet_id,
            dimension: 'ROWS',
            start_index: 1
            # end_index: 2000 -- unbounded if unspecified?
          },
          properties: {
            pixel_size: pixel_height
          },
          fields: 'pixelSize'
        }
      }
    ]

    # Create the batch update request
    batch_update_request = Google::Apis::SheetsV4::BatchUpdateSpreadsheetRequest.new(
      requests: requests
    )

    with_retries { sheets_service.batch_update_spreadsheet(spreadsheet_id, batch_update_request) }
  end

  def approx_batch_size_in_bytes
    rows.map(&:approximate_size_in_bytes).sum
  end

  sig {params(row: GoogleDrive::SpreadsheetRow).void}
  def append_row(row)
    rows << row
    if (approx_batch_size_in_bytes > 1_500_000)
      flush!
    end
  end




end

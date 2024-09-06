class GoogleDrive::Authorizer

  def authorizer
    authorize! unless @authorizer
    @authorizer
  end

private
  def authorize!
    raise_if_invalid_creds!

    opts = {
      scope: [
        'https://www.googleapis.com/auth/spreadsheets',
        'https://www.googleapis.com/auth/drive'
      ]
    }

    if ENV.has_key?("GOOGLE_CLOUD_CREDS")
      opts.merge!(json_key_io: StringIO.new(ENV.fetch("GOOGLE_CLOUD_CREDS")))
    end

    @authorizer = Google::Auth::ServiceAccountCredentials.make_creds(opts)
  end

  def raise_if_invalid_creds!
    unless valid_creds?
      raise "Must pass credentials in ENV, either:
        - GOOGLE_CLOUD_CREDS containing the full JSON credentials structure downloaded from google cloud
        - or GOOGLE_CLIENT_ID GOOGLE_CLIENT_EMAIL GOOGLE_PRIVATE_KEY containing these credentials"
    end
  end

  def valid_creds?
    ENV.has_key?("GOOGLE_CLOUD_CREDS") or
      %W{GOOGLE_CLIENT_ID GOOGLE_CLIENT_EMAIL GOOGLE_PRIVATE_KEY}.all? {|env_var| ENV.has_key?(env_var) }
  end
end

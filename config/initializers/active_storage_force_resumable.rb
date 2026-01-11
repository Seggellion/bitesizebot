# config/initializers/active_storage_gcs_resumable.rb

Rails.application.config.to_prepare do
  service_class = ActiveStorage::Service::GCSService rescue nil
  next if service_class.nil?

  service_class.class_eval do
    def url_for_direct_upload(key, content_type:, checksum:, **)
      creds = @config[:credentials]
      authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: StringIO.new(creds.to_json),
        scope: "https://www.googleapis.com/auth/devstorage.read_write"
      )
      token = authorizer.fetch_access_token!["access_token"]

      origin = ENV.fetch("PUBLIC_ORIGIN", "https://www.railpress.com")

      conn = Faraday.new("https://storage.googleapis.com")
      response = conn.post do |req|
        req.url "/upload/storage/v1/b/#{bucket.name}/o",
                uploadType: "resumable",
                name: key
        req.headers["Authorization"] = "Bearer #{token}"
        req.headers["Origin"] = origin
        req.headers["x-goog-resumable"] = "start"
        req.headers["Content-Type"] = content_type
        req.headers["X-Upload-Content-Type"] = content_type
        req.headers["Content-Length"] = "0"
      end

      response.headers["Location"] || raise("Failed to start resumable session: #{response.status}")
    end
  end
end

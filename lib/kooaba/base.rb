module Kooaba
  QUERY_URL  = "https://query-api.kooaba.com/v4/"
  UPLOAD_URL = "https://upload-api.kooaba.com/api/v4/"

  def self.data_key=(data_key)
    @@data_key = data_key
  end

  def self.query_key=(query_key)
    @@query_key = query_key
  end

  def self.data_key
    @@data_key
  end

  def self.query_key
    @@query_key
  end

  def self.upload(item, bucket_id, method)
    raise ArgumentError, "You need to specify the Data Key before uploading an item" if Kooaba::data_key == nil
    UploadRequest.new(item, bucket_id, method).start
  end

  def self.query(image_path)
    raise ArgumentError, "You need to specify the Query Key before making queries" if Kooaba.query_key == nil
    QueryRequest.new(image_path).start
  end
end

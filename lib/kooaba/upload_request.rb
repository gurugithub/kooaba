require 'rubygems'
require 'uri'
require 'net/http'
require 'net/https'
require 'time'

require 'json'
require 'net/http'


module Kooaba

  class UploadRequest

    attr_accessor :message
    attr_accessor :bucket_id

    attr_accessor :item

    def initialize(item, bucket_id)
      @item = item
      @bucket_id = bucket_id
      @message = MultipartMessage.new
      item.image_files.each do |image_path|
        content_type = `file --mime-type -b #{image_path}`
        @message.add_file_part('images', image_path, content_type)
      end
      @message.add_text_part('reference_id', item.reference_id) if item.reference_id
      @message.add_text_part('title', item.title) if item.title
      @message.add_text_part('enabled', item.enabled)
      @message.add_text_part('metadata', item.metadata) if item.metadata
    end

    #
    # Returns the http response from the Kooaba servers.
    #
    def start
      url = URI.parse(Kooaba::UPLOAD_URL + "buckets/" + bucket_id + "/items")

      resp = make_request(url)
      parse_request(resp)

      return resp
    end

    # URL is the API URL to use.  This is specific and based on Kooaba Documentation
    # Method is the HTTP Method - GET/POST/PUT/DELETE that will be used.
    def make_request(url, method)
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      http.read_timeout = 500
      if method == "POST"
        req = Net::HTTP::Post.new(url.path)
      end

      if method == "PUT"
        req = Net::HTTP::Put.new(url.path)
      end

      req.body = @message.body
      req['date'] = Time.new.httpdate
      req['content-type'] = @message.content_type
      req['authorization'] = "Token #{Kooaba.data_key}"

      http.request(req)
    end

    def parse_request(http_resp)
      case http_resp
      when Net::HTTPSuccess
        parse_2xx(http_resp)
      when Net::HTTPClientError
        parse_4xx(http_resp)
      when Net::HTTPServerError
        parse_5xx(http_resp)
      else
        unknown_response(http_resp)
      end
    end

    def parse_2xx(http_resp)
      json = JSON.parse(http_resp.body)
      @item.uuid = json["uuid"]
      @item.enabled = json["enabled"]
      @item.images_sha1 = json["images"].empty? ? [] : json["images"].map {|a| a["sha1"]}
    end

    def parse_4xx(http_resp)
      # do nothing for now
    end

    def parse_5xx(http_resp)
      # do nothing for now
    end

    def unknown_response(http_resp)
      raise StandardError, "Unknown response: #{http_resp.code} #{http_resp.body} "
    end

  end

end

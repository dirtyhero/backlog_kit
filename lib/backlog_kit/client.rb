require 'backlog_kit/error'
require 'backlog_kit/response'
require 'backlog_kit/version'
require 'backlog_kit/hash_extensions'

module BacklogKit
  class Client
    USER_AGENT = "BacklogKit Ruby Gem #{BacklogKit::VERSION}".freeze

    attr_writer(:space_id, :api_key)

    def initialize(options = {})
      options.each do |key, value|
        instance_variable_set(:"@#{key}", value)
      end
    end

    def space_id
      @space_id ||= ENV['BACKLOG_SPACE_ID']
    end

    def api_key
      @api_key ||= ENV['BACKLOG_API_KEY']
    end

    def get(path, params = {})
      request(:get, path, params)
    end

    def post(path, params = {})
      request(:post, path, params)
    end

    def put(path, params = {})
      request(:put, path, params)
    end

    def patch(path, params = {})
      request(:patch, path, params)
    end

    def delete(path, params = {})
      request(:delete, path, params)
    end

    private

    def request(method, path, params = {})
      params.camelize_keys!
      faraday_response = connection.send(method, request_path(path), params)
      BacklogKit::Response.new(faraday_response)
    rescue Faraday::ConnectionFailed => e
      raise BacklogKit::Error, "#{BacklogKit::ConnectionError.name.demodulize} - #{e.message}"
    end

    def connection
      @connection ||= Faraday.new(url: host, headers: request_headers) do |faraday|
        faraday.request(:url_encoded)
        faraday.response(:json, content_type: /application\/json/)
        faraday.adapter(Faraday.default_adapter)
      end
    end

    def host
      "https://#{space_id}.backlog.jp"
    end

    def request_headers
      { 'User-Agent' => USER_AGENT }
    end

    def request_path(path)
      "/api/v2/#{URI.escape(path)}?apiKey=#{URI.escape(@api_key.to_s)}"
    end
  end
end
require "net/http"
require "json"

# Tiny helper to GET a URL and parse its JSON body, using only Ruby's standard
# library. Raises HttpJson::Error on network problems or a non-200 response.
module HttpJson
  class Error < StandardError; end

  TIMEOUT_SECONDS = 5

  def self.get(url)
    uri = URI(url)
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                               open_timeout: TIMEOUT_SECONDS, read_timeout: TIMEOUT_SECONDS) do |http|
      http.get(uri.request_uri, "Accept" => "application/json")
    end

    raise Error, "#{uri.host} responded #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  rescue JSON::ParserError, SocketError, SystemCallError, Timeout::Error, OpenSSL::SSL::SSLError, Net::HTTPBadResponse => e
    raise Error, "#{uri&.host}: #{e.class}: #{e.message}"
  end
end

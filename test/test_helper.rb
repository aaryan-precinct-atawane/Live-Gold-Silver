ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# Tests never call the real internet. HttpJson.get answers from canned
# responses instead, matched by a piece of the URL.
module FakeHttpJson
  mattr_accessor :responses, default: {}

  def self.reset!
    self.responses = {
      "symbol=XAUUSDT" => { "symbol" => "XAUUSDT", "price" => "3600.00" },
      "symbol=XAGUSDT" => { "symbol" => "XAGUSDT", "price" => "42.00" },
      "api.frankfurter.dev" => { "base" => "USD", "rates" => { "INR" => 90.0 } }
    }
  end

  def get(url)
    _, response = FakeHttpJson.responses.find { |fragment, _| url.include?(fragment) }
    raise HttpJson::Error, "no fake response for #{url}" if response.nil?
    raise response if response.is_a?(Exception)

    response
  end
end
HttpJson.singleton_class.prepend(FakeHttpJson)

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    setup { FakeHttpJson.reset! }

    def create_quote(metal: "gold", price_inr: 324_000, price_usd: 3_600, at: Time.current, rate: 90)
      PriceQuote.create!(metal: metal, price_inr: price_inr, price_usd: price_usd,
                         usd_inr_rate: rate, source: "binance", recorded_at: at)
    end
  end
end

# Fetches live gold and silver prices from Binance's public futures API.
# No API key is needed. Prices are in USDT (a dollar-pegged token) per troy ounce.
class BinancePriceSource
  NAME = "binance".freeze

  SYMBOLS = { "gold" => "XAUUSDT", "silver" => "XAGUSDT" }.freeze

  API_URL = "https://fapi.binance.com/fapi/v1/ticker/price?symbol=%s".freeze
  TRADE_URL = "https://www.binance.com/en/futures/%s".freeze

  def self.trade_url(metal)
    format(TRADE_URL, SYMBOLS.fetch(metal))
  end

  # `fetcher` is how we GET JSON. Tests pass a fake one so they never call the internet.
  def initialize(fetcher: HttpJson.method(:get))
    @fetcher = fetcher
  end

  def name
    NAME
  end

  # Returns the current USD price per troy ounce as a BigDecimal.
  def price_usd(metal)
    data = @fetcher.call(format(API_URL, SYMBOLS.fetch(metal)))
    price = BigDecimal(data.fetch("price").to_s)
    raise HttpJson::Error, "Binance returned a non-positive price for #{metal}" unless price.positive?

    price
  rescue KeyError, ArgumentError, TypeError => e
    raise HttpJson::Error, "Unexpected Binance response for #{metal}: #{e.message}"
  end
end

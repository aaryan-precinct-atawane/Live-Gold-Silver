# The current Binance price for the trading desk, refreshed at most once a second.
#
# The desk asks for prices every second from every open browser tab. Caching for
# one second means Binance is called about once a second no matter how many tabs
# are open (and keeps us far below Binance's rate limits).
module LivePrice
  CACHE_FOR = 1.second

  # USD price per troy ounce as a BigDecimal. Raises HttpJson::Error if Binance fails.
  def self.usd(metal, source: BinancePriceSource.new)
    Rails.cache.fetch("live_price/#{metal}", expires_in: CACHE_FOR) { source.price_usd(metal) }
  end

  # { "gold" => price or nil, "silver" => price or nil }. A metal whose price
  # can't be fetched is nil, so one failure doesn't hide the other price.
  def self.all_usd(source: BinancePriceSource.new)
    PriceQuote::METALS.index_with do |metal|
      usd(metal, source: source)
    rescue HttpJson::Error => e
      Rails.logger.warn("[LivePrice] #{metal} unavailable: #{e.message}")
      nil
    end
  end

  # Rupees per dollar, only for showing prices in INR. Uses the rate the price
  # ticker saved most recently; fetches one if nothing is saved yet. nil if unavailable.
  def self.usd_inr_rate
    PriceQuote.newest_first.pick(:usd_inr_rate) ||
      Rails.cache.fetch("price_ticker/usd_inr_rate", expires_in: PriceTicker::RATE_MAX_AGE) { UsdInrRate.new.current }
  rescue HttpJson::Error
    nil
  end
end

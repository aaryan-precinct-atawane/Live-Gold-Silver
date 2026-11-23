# Publishes the latest live price for each metal.
#
# Every tick it asks the price source (Binance) for the USD price, converts it
# to INR with the USD -> INR rate, and saves a PriceQuote. If the price can't
# be fetched, it skips that metal for this tick, and the dashboard keeps
# showing the last saved price.
class PriceTicker
  # The exchange rate only changes once a day, so reuse it for an hour
  # instead of asking for it every 10 seconds.
  RATE_MAX_AGE = 1.hour

  def self.tick!(at: Time.current)
    new.tick!(at: at)
  end

  def initialize(price_source: BinancePriceSource.new, rate_source: UsdInrRate.new, logger: Rails.logger)
    @price_source = price_source
    @rate_source = rate_source
    @logger = logger
  end

  # Creates one PriceQuote per metal it could fetch, and returns them.
  def tick!(at: Time.current)
    rate = usd_inr_rate
    return [] unless rate

    PriceQuote::METALS.filter_map do |metal|
      price_usd = @price_source.price_usd(metal)

      PriceQuote.create!(
        metal: metal,
        price_usd: price_usd.round(2),
        price_inr: (price_usd * rate).round(2),
        usd_inr_rate: rate,
        source: @price_source.name,
        recorded_at: at
      )
    rescue HttpJson::Error => e
      @logger.warn("[PriceTicker] Skipped #{metal}: #{e.message}")
      nil
    end
  end

  private

  # Fetches the rate at most once an hour (kept in the Rails cache).
  # If fetching fails, falls back to the last rate saved on a quote.
  def usd_inr_rate
    Rails.cache.fetch("price_ticker/usd_inr_rate", expires_in: RATE_MAX_AGE) { @rate_source.current }
  rescue HttpJson::Error => e
    fallback = PriceQuote.newest_first.pick(:usd_inr_rate)
    @logger.warn("[PriceTicker] USD/INR rate unavailable (#{e.message}); " \
                 "#{fallback ? "using last saved rate #{fallback}" : 'skipping this tick'}")
    fallback
  end
end

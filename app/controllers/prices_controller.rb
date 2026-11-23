# The dashboard: the latest live price for each metal.
class PricesController < ApplicationController
  # If the newest price is older than this, the page says prices are delayed.
  STALE_AFTER = 1.minute

  def index
    @latest = PriceQuote::METALS.index_with do |metal|
      PriceQuote.for_metal(metal).newest_first.first
    end
    newest = @latest.values.compact.max_by(&:recorded_at)
    @updated_at = newest&.recorded_at
    @usd_inr_rate = newest&.usd_inr_rate
    @stale = @updated_at.present? && @updated_at < STALE_AFTER.ago
  end
end

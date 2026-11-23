# The dashboard: the latest price for each metal.
class PricesController < ApplicationController
  def index
    @latest = PriceEntry::METALS.index_with do |metal|
      PriceQuote.for_metal(metal).newest_first.first
    end
    @updated_at = @latest.values.compact.map(&:recorded_at).max
  end
end

# One published price for a metal, in USD and INR per troy ounce.
# The ticker creates these from live Binance prices (see PriceTicker).
class PriceQuote < ApplicationRecord
  METALS = %w[gold silver].freeze

  validates :metal, inclusion: { in: METALS }
  validates :price_inr, :price_usd, :usd_inr_rate, numericality: { greater_than: 0 }
  validates :recorded_at, :source, presence: true

  scope :for_metal, ->(metal) { where(metal: metal) }
  scope :newest_first, -> { order(recorded_at: :desc, id: :desc) }

  # The quote published just before this one for the same metal, or nil.
  def previous
    PriceQuote.for_metal(metal)
              .where("recorded_at < :t OR (recorded_at = :t AND id < :id)", t: recorded_at, id: id)
              .newest_first
              .first
  end
end

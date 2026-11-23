# One published ticker price. The dashboard only reads from this table, so it
# doesn't care whether quotes come from manual entries (today) or an API (later).
class PriceQuote < ApplicationRecord
  belongs_to :price_entry, optional: true

  validates :metal, inclusion: { in: PriceEntry::METALS }
  validates :price_inr, :price_usd, numericality: { greater_than: 0 }
  validates :recorded_at, presence: true

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

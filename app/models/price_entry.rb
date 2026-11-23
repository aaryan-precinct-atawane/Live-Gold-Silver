# A price you type in by hand. For each metal, the ticker steps through
# these entries in the order they were created, then loops back to the first.
class PriceEntry < ApplicationRecord
  METALS = %w[gold silver].freeze

  has_many :price_quotes, dependent: :nullify

  validates :metal, inclusion: { in: METALS }
  validates :price_inr, :price_usd, numericality: { greater_than: 0 }

  scope :for_metal, ->(metal) { where(metal: metal) }
  scope :in_cycle_order, -> { order(:id) }
end

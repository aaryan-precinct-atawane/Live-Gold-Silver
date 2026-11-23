# Publishes the next price for each metal.
#
# Today the "next price" is the next manual PriceEntry in the list, looping
# back to the first one at the end. Later, this is the only class that changes
# when prices come from a real API.
class PriceTicker
  def self.tick!(at: Time.current)
    new.tick!(at: at)
  end

  # Creates one PriceQuote per metal that has entries, and returns them.
  def tick!(at: Time.current)
    PriceEntry::METALS.filter_map do |metal|
      entry = next_entry_for(metal)
      next unless entry

      PriceQuote.create!(
        metal: metal,
        price_inr: entry.price_inr,
        price_usd: entry.price_usd,
        recorded_at: at,
        price_entry: entry
      )
    end
  end

  private

  def next_entry_for(metal)
    entries = PriceEntry.for_metal(metal).in_cycle_order
    last_used_id = PriceQuote.for_metal(metal)
                             .where.not(price_entry_id: nil)
                             .newest_first
                             .pick(:price_entry_id)

    return entries.first unless last_used_id

    # The entry after the last one used, or loop back to the start.
    entries.where("id > ?", last_used_id).first || entries.first
  end
end

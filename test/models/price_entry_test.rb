require "test_helper"

class PriceEntryTest < ActiveSupport::TestCase
  test "fixture is valid" do
    assert price_entries(:gold_low).valid?
  end

  test "metal must be gold or silver" do
    entry = PriceEntry.new(metal: "platinum", price_inr: 1, price_usd: 1)
    assert_not entry.valid?
    assert_includes entry.errors[:metal], "is not included in the list"
  end

  test "prices must be greater than zero" do
    entry = PriceEntry.new(metal: "gold", price_inr: 0, price_usd: -5)
    assert_not entry.valid?
    assert entry.errors[:price_inr].any?
    assert entry.errors[:price_usd].any?
  end

  test "prices are required" do
    entry = PriceEntry.new(metal: "gold")
    assert_not entry.valid?
    assert entry.errors[:price_inr].any?
  end

  test "deleting an entry keeps its quotes but unlinks them" do
    entry = price_entries(:gold_low)
    quote = PriceQuote.create!(metal: "gold", price_inr: 1, price_usd: 1,
                               recorded_at: Time.current, price_entry: entry)
    entry.destroy
    assert_nil quote.reload.price_entry_id
  end
end

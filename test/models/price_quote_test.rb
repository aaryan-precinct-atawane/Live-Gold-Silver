require "test_helper"

class PriceQuoteTest < ActiveSupport::TestCase
  def quote(metal:, price:, at:)
    PriceQuote.create!(metal: metal, price_inr: price, price_usd: price, recorded_at: at)
  end

  test "requires metal, prices and recorded_at" do
    q = PriceQuote.new
    assert_not q.valid?
    assert q.errors[:metal].any?
    assert q.errors[:price_inr].any?
    assert q.errors[:recorded_at].any?
  end

  test "price_entry is optional (for future API quotes)" do
    assert PriceQuote.new(metal: "gold", price_inr: 1, price_usd: 1, recorded_at: Time.current).valid?
  end

  test "previous returns the earlier quote for the same metal only" do
    first  = quote(metal: "gold",   price: 100, at: 3.minutes.ago)
    quote(metal: "silver", price: 50, at: 2.minutes.ago)
    latest = quote(metal: "gold",   price: 110, at: 1.minute.ago)

    assert_equal first, latest.previous
    assert_nil first.previous
  end

  test "newest_first orders by recorded_at" do
    older = quote(metal: "gold", price: 100, at: 2.minutes.ago)
    newer = quote(metal: "gold", price: 110, at: 1.minute.ago)
    assert_equal [ newer, older ], PriceQuote.newest_first.to_a
  end
end

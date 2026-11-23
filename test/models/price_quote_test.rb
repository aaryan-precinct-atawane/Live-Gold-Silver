require "test_helper"

class PriceQuoteTest < ActiveSupport::TestCase
  test "requires metal, prices, rate, source and recorded_at" do
    quote = PriceQuote.new
    assert_not quote.valid?
    %i[metal price_inr price_usd usd_inr_rate source recorded_at].each do |field|
      assert quote.errors[field].any?, "expected an error on #{field}"
    end
  end

  test "metal must be gold or silver" do
    quote = PriceQuote.new(metal: "platinum")
    assert_not quote.valid?
    assert_includes quote.errors[:metal], "is not included in the list"
  end

  test "previous returns the earlier quote for the same metal only" do
    first  = create_quote(metal: "gold", at: 3.minutes.ago)
    create_quote(metal: "silver", price_inr: 3_780, price_usd: 42, at: 2.minutes.ago)
    latest = create_quote(metal: "gold", at: 1.minute.ago)

    assert_equal first, latest.previous
    assert_nil first.previous
  end

  test "newest_first orders by recorded_at" do
    older = create_quote(at: 2.minutes.ago)
    newer = create_quote(at: 1.minute.ago)
    assert_equal [ newer, older ], PriceQuote.newest_first.to_a
  end
end

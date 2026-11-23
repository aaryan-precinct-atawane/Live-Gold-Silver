require "test_helper"

class PriceTickerTest < ActiveSupport::TestCase
  setup do
    # Start from a known list so the cycle order is predictable.
    PriceEntry.delete_all
    @gold = [ 100, 200, 300 ].map { |p| PriceEntry.create!(metal: "gold", price_inr: p, price_usd: p / 10.0) }
    @clock = Time.current
  end

  # Ticks `times` times, 10 seconds apart (like the real job), and returns
  # the gold INR prices that were published.
  def tick_gold_prices(times)
    times.times.map do
      @clock += 10.seconds
      PriceTicker.tick!(at: @clock).find { |q| q.metal == "gold" }.price_inr.to_i
    end
  end

  test "first tick publishes the first entry" do
    quotes = PriceTicker.tick!
    assert_equal 1, quotes.size
    assert_equal @gold.first, quotes.first.price_entry
    assert_equal 100, quotes.first.price_inr
  end

  test "steps through entries in order and loops back to the start" do
    assert_equal [ 100, 200, 300, 100, 200 ], tick_gold_prices(5)
  end

  test "skips a metal with no entries" do
    assert_equal [ "gold" ], PriceTicker.tick!.map(&:metal)
  end

  test "ticks each metal independently" do
    PriceEntry.create!(metal: "silver", price_inr: 50, price_usd: 5)
    quotes = PriceTicker.tick!
    assert_equal %w[gold silver], quotes.map(&:metal)
  end

  test "an entry added later joins the end of the cycle" do
    tick_gold_prices(3) # 100, 200, 300
    PriceEntry.create!(metal: "gold", price_inr: 400, price_usd: 40)
    assert_equal [ 400, 100 ], tick_gold_prices(2)
  end

  test "deleting the last used entry continues from the entry before it" do
    tick_gold_prices(2) # 100, 200
    @gold.second.destroy
    # The newest quote still linked to an entry is the one for 100, so 300 comes next.
    assert_equal [ 300, 100 ], tick_gold_prices(2)
  end
end

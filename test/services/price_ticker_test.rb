require "test_helper"

class PriceTickerTest < ActiveSupport::TestCase
  test "saves one quote per metal, converted to INR" do
    quotes = PriceTicker.tick!

    assert_equal %w[gold silver], quotes.map(&:metal)
    gold = quotes.first
    assert_equal BigDecimal("3600"), gold.price_usd
    assert_equal BigDecimal("324000"), gold.price_inr # 3600 x 90
    assert_equal BigDecimal("90"), gold.usd_inr_rate
    assert_equal "binance", gold.source
    assert_equal BigDecimal("3780"), quotes.last.price_inr # 42 x 90
  end

  test "skips a metal whose price can't be fetched, and still saves the other" do
    FakeHttpJson.responses["symbol=XAGUSDT"] = HttpJson::Error.new("timeout")

    assert_equal [ "gold" ], PriceTicker.tick!.map(&:metal)
  end

  test "falls back to the last saved rate when the rate API fails" do
    create_quote(rate: 88.5, at: 1.day.ago)
    FakeHttpJson.responses["api.frankfurter.dev"] = HttpJson::Error.new("down")

    gold = PriceTicker.tick!.first
    assert_equal BigDecimal("88.5"), gold.usd_inr_rate
    assert_equal BigDecimal("318600"), gold.price_inr # 3600 x 88.5
  end

  test "saves nothing when there is no rate at all" do
    FakeHttpJson.responses["api.frankfurter.dev"] = HttpJson::Error.new("down")

    assert_no_difference -> { PriceQuote.count } do
      assert_equal [], PriceTicker.tick!
    end
  end

  test "reuses the rate for an hour instead of fetching it every tick" do
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    rate_calls = 0
    rate_source = Object.new
    rate_source.define_singleton_method(:current) { rate_calls += 1; BigDecimal("90") }
    ticker = PriceTicker.new(rate_source: rate_source)

    3.times { ticker.tick! }
    assert_equal 1, rate_calls

    travel(61.minutes) { ticker.tick! }
    assert_equal 2, rate_calls
  ensure
    Rails.cache = original_cache
  end
end

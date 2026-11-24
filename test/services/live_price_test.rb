require "test_helper"

class LivePriceTest < ActiveSupport::TestCase
  test "returns the Binance USD price" do
    assert_equal BigDecimal("3600.00"), LivePrice.usd("gold")
  end

  test "all_usd returns nil for a metal Binance can't price, and keeps the other" do
    FakeHttpJson.responses["symbol=XAGUSDT"] = HttpJson::Error.new("timeout")
    assert_equal({ "gold" => BigDecimal("3600.00"), "silver" => nil }, LivePrice.all_usd)
  end

  test "usd_inr_rate prefers the rate the ticker saved last" do
    create_quote(rate: 93.25)
    assert_equal BigDecimal("93.25"), LivePrice.usd_inr_rate
  end

  test "usd_inr_rate fetches a rate when none is saved, and is nil if that fails" do
    assert_equal BigDecimal("90.0"), LivePrice.usd_inr_rate

    FakeHttpJson.responses["api.frankfurter.dev"] = HttpJson::Error.new("down")
    assert_nil LivePrice.usd_inr_rate
  end
end

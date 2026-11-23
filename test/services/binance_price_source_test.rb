require "test_helper"

class BinancePriceSourceTest < ActiveSupport::TestCase
  test "returns the USD price for each metal" do
    source = BinancePriceSource.new
    assert_equal BigDecimal("3600.00"), source.price_usd("gold")
    assert_equal BigDecimal("42.00"), source.price_usd("silver")
  end

  test "asks Binance for the right symbol" do
    urls = []
    source = BinancePriceSource.new(fetcher: ->(url) { urls << url; { "price" => "1" } })
    source.price_usd("silver")
    assert_equal [ "https://fapi.binance.com/fapi/v1/ticker/price?symbol=XAGUSDT" ], urls
  end

  test "raises HttpJson::Error on an unexpected response" do
    source = BinancePriceSource.new(fetcher: ->(_url) { { "msg" => "Invalid symbol." } })
    assert_raises(HttpJson::Error) { source.price_usd("gold") }
  end

  test "raises HttpJson::Error on a zero price" do
    source = BinancePriceSource.new(fetcher: ->(_url) { { "price" => "0" } })
    assert_raises(HttpJson::Error) { source.price_usd("gold") }
  end

  test "trade_url points to the Binance futures page" do
    assert_equal "https://www.binance.com/en/futures/XAUUSDT", BinancePriceSource.trade_url("gold")
    assert_equal "https://www.binance.com/en/futures/XAGUSDT", BinancePriceSource.trade_url("silver")
  end
end

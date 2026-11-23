require "test_helper"

class PricesControllerTest < ActionDispatch::IntegrationTest
  test "shows a waiting state before the first live price" do
    get prices_path
    assert_response :success
    assert_select "#card_gold", /Waiting for the first live price/
    assert_select ".updated", 0
  end

  test "shows the latest price per ounce with Indian grouping and the change" do
    create_quote(price_inr: 324_000, price_usd: 3_600, at: 20.seconds.ago)
    create_quote(price_inr: 336_227.45, price_usd: 3_590, at: 10.seconds.ago, rate: 93.65)

    get prices_path
    assert_response :success
    assert_select "#card_gold .market__unit", "per troy ounce"
    assert_select "#card_gold .price__value", "₹3,36,227.45"
    assert_select "#card_gold .change--up", /▲ 12,227\.45/
    assert_select "#card_gold .change--down", /▼ 10\.00/
    assert_select ".updated", /1 USD = ₹93\.6500/
    assert_select ".flash--alert", 0
  end

  test "warns when prices are delayed" do
    create_quote(at: 5.minutes.ago)
    get prices_path
    assert_select ".flash--alert", /delayed/
  end

  test "buy buttons open Binance gold and silver futures in a new tab" do
    get prices_path
    assert_select "#card_gold a.button--buy[href=?][target=_blank][rel='noopener noreferrer']",
                  "https://www.binance.com/en/futures/XAUUSDT", text: "Buy Gold on Binance ↗"
    assert_select "#card_silver a.button--buy[href=?][target=_blank]",
                  "https://www.binance.com/en/futures/XAGUSDT", text: "Buy Silver on Binance ↗"
    assert_select "#card_gold .risk-note", /leveraged futures, high risk/
  end

  test "auto-refreshes with morphing" do
    get prices_path
    assert_select "[data-controller='auto-refresh']"
    assert_select "meta[name='turbo-refresh-method'][content='morph']"
  end
end

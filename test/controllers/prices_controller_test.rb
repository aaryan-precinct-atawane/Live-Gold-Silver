require "test_helper"

class PricesControllerTest < ActionDispatch::IntegrationTest
  test "shows an empty state before any ticks" do
    get prices_path
    assert_response :success
    assert_select "#card_gold", /No prices yet/
    assert_select "#card_silver", /No prices yet/
    assert_select ".updated", 0
  end

  test "shows the latest price and the change since the previous tick" do
    PriceQuote.create!(metal: "gold", price_inr: 76_500, price_usd: 2_650, recorded_at: 1.minute.ago)
    PriceQuote.create!(metal: "gold", price_inr: 76_820, price_usd: 2_640, recorded_at: Time.current)

    get prices_path
    assert_response :success
    assert_select "#card_gold .price__value", "₹76,820.00"
    assert_select "#card_gold .change--up", /▲ 320\.00/
    assert_select "#card_gold .change--down", /▼ 10\.00/
    assert_select ".updated", /IST/
  end

  test "no recent ticks table" do
    PriceQuote.create!(metal: "gold", price_inr: 1, price_usd: 1, recorded_at: Time.current)
    get prices_path
    assert_select "table", 0
  end

  test "buy buttons under each metal lead back to the prices page" do
    get prices_path
    assert_select "#card_gold a.button--buy[href=?]", prices_path, text: "Buy Gold"
    assert_select "#card_silver a.button--buy[href=?]", prices_path, text: "Buy Silver"
  end

  test "auto-refreshes with morphing" do
    get prices_path
    assert_select "[data-controller='auto-refresh']"
    assert_select "meta[name='turbo-refresh-method'][content='morph']"
  end
end

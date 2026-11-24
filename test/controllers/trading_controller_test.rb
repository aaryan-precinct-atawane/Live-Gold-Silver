require "test_helper"

class TradingControllerTest < ActionDispatch::IntegrationTest
  def account
    PracticeAccount.order(:id).last
  end

  test "first visit creates a practice account with ₹10,00,000 and shows the desk" do
    assert_difference -> { PracticeAccount.count }, 1 do
      get trading_path
    end
    assert_response :success
    assert_select "h1", "Binary Trading"
    assert_select "[data-trade-desk-target=balance]", "₹10,00,000.00"
    assert_select ".tile--gold .tile__price", /\$3,600\.00/
    assert_select "button[name='practice_trade[direction]'][value=up]"
    assert_select "button[name='practice_trade[direction]'][value=down]"
  end

  test "the same browser keeps its account" do
    get trading_path
    assert_no_difference -> { PracticeAccount.count } do
      get trading_path
    end
  end

  test "live returns prices, balance and the live P&L of open trades" do
    get trading_path
    trade = account.open_trade!(metal: "gold", direction: "up", stake_inr: 10_000, leverage: 20,
                                duration_seconds: 60, entry_price_usd: 3_590)

    get trading_live_path(format: :json)
    assert_response :success
    json = response.parsed_body

    assert_equal({ "gold" => 3600.0, "silver" => 42.0 }, json["prices"])
    assert_equal 990_000.0, json["balance_inr"]
    live = json["open_trades"].sole
    assert_equal trade.id, live["id"]
    assert_in_delta 557.10, live["pnl_inr"], 0.01        # 10,000 × 20 × (3600 / 3590 - 1)
    assert_in_delta 1.0557, live["value_multiple"], 0.0001
  end

  test "live settles trades that have expired" do
    get trading_path
    trade = account.open_trade!(metal: "gold", direction: "up", stake_inr: 10_000, leverage: 20,
                                duration_seconds: 30, entry_price_usd: 3_600, at: 1.minute.ago)

    get trading_live_path(format: :json)
    assert_empty response.parsed_body["open_trades"]
    assert_equal "expired", trade.reload.close_reason
  end

  test "reset restores the balance" do
    get trading_path
    account.update!(balance_inr: 5)

    post reset_trading_path
    assert_redirected_to trading_path
    assert_equal BigDecimal("1000000"), account.reload.balance_inr
  end

  test "every page has a Binary Trading button in the header" do
    [ root_path, prices_path, trading_path ].each do |path|
      get path
      assert_select "nav a.button--cta[href=?]", trading_path, text: "▲▼ Binary Trading"
    end
  end

  test "homepage and live prices page also link to Binary Trading" do
    get root_path
    assert_select ".hero a[href=?]", trading_path, text: "▲▼ Start Binary Trading"
    get prices_path
    assert_select ".cta-strip a[href=?]", trading_path
  end
end

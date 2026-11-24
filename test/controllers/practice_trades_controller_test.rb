require "test_helper"

class PracticeTradesControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    get trading_path # creates this browser's practice account
    @account = PracticeAccount.order(:id).last
  end

  def place(direction: "up", metal: "gold", stake: 10_000, leverage: 20, duration: 60)
    post practice_trades_path, params: { practice_trade: {
      metal: metal, direction: direction, stake_inr: stake, leverage: leverage, duration_seconds: duration
    } }
  end

  test "opens a trade at the live price, takes the stake and schedules settlement" do
    assert_enqueued_jobs 1, only: SettlePracticeTradeJob do
      place(direction: "down", leverage: 50, duration: 120)
    end
    assert_redirected_to trading_path
    assert_match(/Opened Gold DOWN 50× at \$3600\.00/, flash[:notice])

    trade = @account.practice_trades.sole
    assert_equal BigDecimal("3600"), trade.entry_price_usd
    assert_equal 120, trade.duration_seconds
    assert_equal BigDecimal("990000"), @account.reload.balance_inr
  end

  test "remembers the last form choices" do
    place(metal: "silver", stake: 2_500, leverage: 5, duration: 300)
    follow_redirect!
    assert_select "input[name='practice_trade[metal]'][value=silver][checked]"
    assert_select "input[name='practice_trade[stake_inr]'][value='2500']"
    assert_select "input[name='practice_trade[leverage]'][value='5'][checked]"
    assert_select "input[name='practice_trade[duration_seconds]'][value='300'][checked]"
  end

  test "rejects an invalid trade without touching the balance" do
    place(leverage: 7)
    assert_redirected_to trading_path
    assert_match(/Leverage is not included/, flash[:alert])
    assert_equal BigDecimal("1000000"), @account.reload.balance_inr
  end

  test "rejects an unknown metal" do
    place(metal: "platinum")
    assert_equal "Choose gold or silver.", flash[:alert]
    assert_equal 0, @account.practice_trades.count
  end

  test "says so when Binance is unavailable" do
    FakeHttpJson.responses["symbol=XAUUSDT"] = HttpJson::Error.new("timeout")
    place
    assert_match(/Couldn't get a live price/, flash[:alert])
    assert_equal 0, @account.practice_trades.count
  end

  test "close now closes the trade at the live price" do
    trade = @account.open_trade!(metal: "gold", direction: "up", stake_inr: 10_000, leverage: 10,
                                 duration_seconds: 300, entry_price_usd: 3_500)

    post close_practice_trade_path(trade)
    assert_redirected_to trading_path
    trade.reload
    assert_equal "manual", trade.close_reason
    assert_equal BigDecimal("2857.14"), trade.pnl_inr # 10,000 × 10 × (3600 / 3500 - 1)
    assert_match(/P&L: \+₹2,857\.14/, flash[:notice])
  end

  test "cannot close another browser's trade" do
    other = PracticeAccount.create!.open_trade!(metal: "gold", direction: "up", stake_inr: 1_000, leverage: 5,
                                                duration_seconds: 60, entry_price_usd: 3_600)
    post close_practice_trade_path(other)
    assert_response :not_found
    assert other.reload.open?
  end
end

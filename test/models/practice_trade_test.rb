require "test_helper"

class PracticeTradeTest < ActiveSupport::TestCase
  setup do
    @account = PracticeAccount.create!
  end

  def open_trade(direction: "up", stake: 10_000, leverage: 20, duration: 60, entry: 3600, at: Time.current)
    @account.open_trade!(metal: "gold", direction: direction, stake_inr: stake, leverage: leverage,
                         duration_seconds: duration, entry_price_usd: entry, at: at)
  end

  test "UP trade: P&L = stake × leverage × % move" do
    trade = open_trade(direction: "up")
    assert_equal BigDecimal("200"), trade.pnl_at(3_603.6)    # +0.1% × 20 × 10,000
    assert_equal BigDecimal("-200"), trade.pnl_at(3_596.4)   # -0.1%
    assert_equal BigDecimal("1.02"), trade.value_multiple_at(3_603.6)
  end

  test "DOWN trade profits when the price falls" do
    trade = open_trade(direction: "down")
    assert_equal BigDecimal("200"), trade.pnl_at(3_596.4)
    assert_equal BigDecimal("-200"), trade.pnl_at(3_603.6)
  end

  test "loss is capped at the stake" do
    trade = open_trade(direction: "up", leverage: 50)
    assert_equal BigDecimal("-10000"), trade.pnl_at(3_000)   # -16.7% × 50 would be -83,333
    assert_equal 0, trade.value_multiple_at(3_000)
    assert trade.stopped_out_at?(3_528)                     # exactly -2% × 50 = -100%
    assert_not trade.stopped_out_at?(3_529)
  end

  test "close! pays stake + P&L back into the balance, only once" do
    trade = open_trade(stake: 10_000)
    assert_equal BigDecimal("990000"), @account.reload.balance_inr

    assert trade.close!(3_603.6, reason: "manual")
    assert_not trade.close!(3_700, reason: "manual"), "second close should do nothing"

    trade.reload
    assert_equal "closed", trade.status
    assert_equal "manual", trade.close_reason
    assert_equal BigDecimal("200"), trade.pnl_inr
    assert_equal BigDecimal("3603.6"), trade.exit_price_usd
    assert_equal BigDecimal("1000200"), @account.reload.balance_inr
  end

  test "settle_if_due! closes expired trades" do
    trade = open_trade(duration: 30, at: 31.seconds.ago)
    assert trade.settle_if_due!(3_600)
    assert_equal "expired", trade.reload.close_reason
    assert_equal BigDecimal("1000000"), @account.reload.balance_inr # break-even
  end

  test "settle_if_due! stops out a trade whose loss reached the stake" do
    trade = open_trade(leverage: 50)
    assert trade.settle_if_due!(3_500)
    assert_equal "stopped_out", trade.reload.close_reason
    assert_equal BigDecimal("-10000"), trade.pnl_inr
    assert_equal BigDecimal("990000"), @account.reload.balance_inr
  end

  test "settle_if_due! leaves a running trade open" do
    trade = open_trade
    assert_not trade.settle_if_due!(3_601)
    assert trade.reload.open?
  end

  test "validates leverage, expiry, direction and minimum stake" do
    trade = @account.practice_trades.build(metal: "platinum", direction: "sideways", stake_inr: 50,
                                           leverage: 7, duration_seconds: 45, entry_price_usd: 3600,
                                           opened_at: Time.current, expires_at: Time.current)
    assert_not trade.valid?
    %i[metal direction stake_inr leverage duration_seconds].each do |field|
      assert trade.errors[field].any?, "expected an error on #{field}"
    end
  end
end

require "test_helper"

class SettlePracticeTradeJobTest < ActiveJob::TestCase
  setup do
    @account = PracticeAccount.create!
  end

  def open_trade(at:)
    @account.open_trade!(metal: "gold", direction: "up", stake_inr: 10_000, leverage: 20,
                         duration_seconds: 30, entry_price_usd: 3_590, at: at)
  end

  test "closes an expired trade at the live Binance price" do
    trade = open_trade(at: 31.seconds.ago)
    SettlePracticeTradeJob.perform_now(trade.id)

    trade.reload
    assert_equal "expired", trade.close_reason
    assert_equal BigDecimal("3600"), trade.exit_price_usd # from the fake Binance response
    assert trade.pnl_inr.positive?
  end

  test "re-queues itself if it runs before the expiry" do
    trade = open_trade(at: Time.current)
    assert_enqueued_with(job: SettlePracticeTradeJob, args: [ trade.id ]) do
      SettlePracticeTradeJob.perform_now(trade.id)
    end
    assert trade.reload.open?
  end

  test "does nothing for a trade that is already closed or deleted" do
    trade = open_trade(at: 31.seconds.ago)
    trade.close!(3_595, reason: "manual")

    SettlePracticeTradeJob.perform_now(trade.id)
    assert_equal "manual", trade.reload.close_reason

    assert_nothing_raised { SettlePracticeTradeJob.perform_now(-1) }
  end
end

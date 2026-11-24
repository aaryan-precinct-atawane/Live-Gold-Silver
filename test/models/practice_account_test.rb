require "test_helper"

class PracticeAccountTest < ActiveSupport::TestCase
  def trade_args(stake:)
    { metal: "gold", direction: "up", stake_inr: stake, leverage: 10, duration_seconds: 60, entry_price_usd: 3600 }
  end

  test "starts with ₹10,00,000 and a random token" do
    account = PracticeAccount.create!
    assert_equal BigDecimal("1000000"), account.balance_inr
    assert account.token.present?
  end

  test "open_trade! takes the stake out of the balance" do
    account = PracticeAccount.create!
    trade = account.open_trade!(**trade_args(stake: 25_000))

    assert trade.persisted?
    assert trade.open?
    assert_equal trade.opened_at + 60.seconds, trade.expires_at
    assert_equal BigDecimal("975000"), account.reload.balance_inr
  end

  test "open_trade! refuses a stake bigger than the balance and changes nothing" do
    account = PracticeAccount.create!(balance_inr: 1_000)

    error = assert_raises(ActiveRecord::RecordInvalid) { account.open_trade!(**trade_args(stake: 5_000)) }
    assert_includes error.record.errors[:stake_inr], "is more than your balance"
    assert_equal BigDecimal("1000"), account.reload.balance_inr
    assert_equal 0, account.practice_trades.count
  end

  test "reset! deletes trades and restores the starting balance" do
    account = PracticeAccount.create!
    account.open_trade!(**trade_args(stake: 50_000))

    account.reset!
    assert_equal BigDecimal("1000000"), account.reload.balance_inr
    assert_equal 0, account.practice_trades.count
  end
end

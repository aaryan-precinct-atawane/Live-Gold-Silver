# A dummy-money trading account, one per browser (see CurrentPracticeAccount).
class PracticeAccount < ApplicationRecord
  STARTING_BALANCE_INR = 10_00_000 # ₹10,00,000

  has_secure_token :token
  has_many :practice_trades, dependent: :delete_all

  validates :balance_inr, numericality: { greater_than_or_equal_to: 0 }

  # Takes the stake out of the balance and opens the trade, all or nothing.
  # Raises ActiveRecord::RecordInvalid if the trade isn't valid (e.g. stake > balance).
  def open_trade!(metal:, direction:, stake_inr:, leverage:, duration_seconds:, entry_price_usd:, at: Time.current)
    transaction do
      # Lock the account row so two quick clicks can't both spend the same money.
      lock!
      trade = practice_trades.create!(
        metal: metal, direction: direction, stake_inr: stake_inr,
        leverage: leverage, duration_seconds: duration_seconds,
        entry_price_usd: entry_price_usd,
        opened_at: at, expires_at: at + duration_seconds.to_i.seconds
      )
      update!(balance_inr: balance_inr - trade.stake_inr)
      trade
    end
  end

  # Wipes all trades and puts the balance back to the starting amount.
  def reset!
    transaction do
      practice_trades.delete_all
      update!(balance_inr: STARTING_BALANCE_INR)
    end
  end
end

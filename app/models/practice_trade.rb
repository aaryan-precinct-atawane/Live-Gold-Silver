# A leveraged UP/DOWN practice trade on gold or silver, paid in virtual rupees.
#
#   P&L = stake × leverage × % price move   (negative if the price went the wrong way)
#
# The loss is capped at the stake: when it reaches the full stake the trade is
# "stopped out". Otherwise the trade closes at its expiry, or earlier if the
# trader clicks Close. Prices are in USD, but P&L only depends on the % move,
# so no currency conversion is needed.
class PracticeTrade < ApplicationRecord
  DIRECTIONS = %w[up down].freeze
  LEVERAGES = [ 5, 10, 20, 50 ].freeze
  DURATIONS = { 30 => "30s", 60 => "1m", 120 => "2m", 300 => "5m" }.freeze
  CLOSE_REASONS = %w[expired manual stopped_out].freeze
  MIN_STAKE_INR = 100

  belongs_to :practice_account

  validates :metal, inclusion: { in: PriceQuote::METALS }
  validates :direction, inclusion: { in: DIRECTIONS }
  validates :leverage, inclusion: { in: LEVERAGES }
  validates :duration_seconds, inclusion: { in: DURATIONS.keys }
  validates :stake_inr, numericality: { greater_than_or_equal_to: MIN_STAKE_INR }
  validates :entry_price_usd, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: %w[open closed] }
  validates :close_reason, inclusion: { in: CLOSE_REASONS }, allow_nil: true
  validate :stake_within_balance, on: :create

  scope :active, -> { where(status: "open") }
  scope :closed, -> { where(status: "closed") }

  def open?
    status == "open"
  end

  def expired?(now = Time.current)
    expires_at <= now
  end

  # Profit or loss in rupees if the trade closed at `price_usd`. Never below -stake.
  def pnl_at(price_usd)
    move = (price_usd.to_d - entry_price_usd) / entry_price_usd
    move = -move if direction == "down"
    [ (stake_inr * leverage * move).round(2), -stake_inr ].max
  end

  # What the trade is worth as a multiple of the stake: 1.00× = break-even, 0× = stake lost.
  def value_multiple_at(price_usd)
    (stake_inr + pnl_at(price_usd)) / stake_inr
  end

  def stopped_out_at?(price_usd)
    pnl_at(price_usd) <= -stake_inr
  end

  # Closes the trade at `price_usd` and pays stake + P&L back into the balance.
  # Safe to call twice (e.g. the expiry job and the page both settling it):
  # only the first call does anything. Returns true if this call closed it.
  def close!(price_usd, reason:, at: Time.current)
    closed_now = false
    transaction do
      lock! # re-reads the row and blocks anyone else settling it at the same time
      if open?
        pnl = pnl_at(price_usd)
        update!(status: "closed", close_reason: reason, exit_price_usd: price_usd, pnl_inr: pnl, closed_at: at)
        practice_account.lock!
        practice_account.update!(balance_inr: practice_account.balance_inr + stake_inr + pnl)
        closed_now = true
      end
    end
    closed_now
  end

  # Closes the trade if it has expired or its loss reached the full stake.
  def settle_if_due!(price_usd, at: Time.current)
    if expired?(at)
      close!(price_usd, reason: "expired", at: at)
    elsif stopped_out_at?(price_usd)
      close!(price_usd, reason: "stopped_out", at: at)
    else
      false
    end
  end

  private

  def stake_within_balance
    return if stake_inr.nil? || practice_account.nil?

    if stake_inr > practice_account.balance_inr
      errors.add(:stake_inr, "is more than your balance")
    end
  end
end

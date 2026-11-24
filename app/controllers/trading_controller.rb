# The practice trading desk: live prices, the order form, open trades and history.
class TradingController < ApplicationController
  include CurrentPracticeAccount

  # How much recent price history (from the price ticker) to seed the chart with.
  CHART_WINDOW = 5.minutes

  def show
    @account = current_practice_account
    @prices = LivePrice.all_usd
    settle_due_trades(@prices)
    @account.reload

    @usd_inr_rate = LivePrice.usd_inr_rate
    @open_trades = @account.practice_trades.active.order(:expires_at)
    @closed_trades = @account.practice_trades.closed.order(closed_at: :desc).limit(20)
    @form = trade_form_defaults
    @chart_history = chart_history
  end

  # Polled every second by the desk (trade_desk_controller.js).
  def live
    prices = LivePrice.all_usd
    settle_due_trades(prices)
    account = current_practice_account.reload

    render json: {
      server_time: (Time.current.to_f * 1000).round,
      usd_inr_rate: LivePrice.usd_inr_rate&.to_f,
      prices: prices.transform_values { |p| p&.to_f },
      balance_inr: account.balance_inr.to_f,
      open_trades: account.practice_trades.active.map do |trade|
        price = prices[trade.metal]
        {
          id: trade.id,
          price_usd: price&.to_f,
          pnl_inr: price && trade.pnl_at(price).to_f,
          value_multiple: price && trade.value_multiple_at(price).round(4).to_f
        }
      end
    }
  end

  def reset
    current_practice_account.reset!
    redirect_to trading_path, notice: "Practice account reset to ₹10,00,000."
  end

  private

  # The order form remembers the last metal, stake, leverage and expiry used.
  def trade_form_defaults
    { "metal" => "gold", "stake_inr" => 10_000, "leverage" => 20, "duration_seconds" => 60 }
      .merge(session[:trade_form] || {})
  end

  # { "gold" => [[ms, price], ...], "silver" => ... } from the ticker's saved quotes.
  def chart_history
    PriceQuote::METALS.index_with do |metal|
      PriceQuote.for_metal(metal).where(recorded_at: CHART_WINDOW.ago..)
                .order(:recorded_at).pluck(:recorded_at, :price_usd)
                .map { |at, price| [ (at.to_f * 1000).round, price.to_f ] }
    end
  end
end

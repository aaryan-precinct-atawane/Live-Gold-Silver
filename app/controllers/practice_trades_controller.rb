# Opens and closes practice trades. Both redirect back to the trading desk.
class PracticeTradesController < ApplicationController
  include CurrentPracticeAccount

  def create
    attrs = trade_params
    session[:trade_form] = attrs.slice(:metal, :stake_inr, :leverage, :duration_seconds).to_h

    unless PriceQuote::METALS.include?(attrs[:metal])
      return redirect_to trading_path, alert: "Choose gold or silver."
    end

    entry_price = LivePrice.usd(attrs[:metal])
    trade = current_practice_account.open_trade!(
      metal: attrs[:metal],
      direction: attrs[:direction],
      stake_inr: attrs[:stake_inr],
      leverage: attrs[:leverage],
      duration_seconds: attrs[:duration_seconds],
      entry_price_usd: entry_price
    )
    SettlePracticeTradeJob.set(wait_until: trade.expires_at).perform_later(trade.id)

    redirect_to trading_path, notice: "Opened #{trade.metal.capitalize} #{trade.direction.upcase} " \
                                      "#{trade.leverage}× at $#{format('%.2f', trade.entry_price_usd)}."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to trading_path, alert: "Trade not opened: #{e.record.errors.full_messages.to_sentence}."
  rescue HttpJson::Error
    redirect_to trading_path, alert: "Couldn't get a live price from Binance. Please try again."
  end

  def close
    trade = current_practice_account.practice_trades.find(params[:id])
    price = LivePrice.usd(trade.metal)
    trade.settle_if_due!(price) || trade.close!(price, reason: "manual")

    trade.reload
    redirect_to trading_path, notice: "Trade closed. P&L: #{helpers.signed_inr(trade.pnl_inr)}."
  rescue HttpJson::Error
    redirect_to trading_path, alert: "Couldn't get a live price from Binance, so the trade is still open."
  end

  private

  def trade_params
    params.expect(practice_trade: [ :metal, :direction, :stake_inr, :leverage, :duration_seconds ])
  end
end

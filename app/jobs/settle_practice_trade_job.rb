# Closes a practice trade at its expiry time with the live Binance price.
# Queued by PracticeTradesController#create with `wait_until: trade.expires_at`.
#
# The trading page also settles overdue trades whenever it asks for prices, so a
# trade still closes if the job runner isn't running; close! makes sure only one
# of them actually closes it.
class SettlePracticeTradeJob < ApplicationJob
  queue_as :default

  # Binance hiccup: try again a couple of seconds later.
  retry_on HttpJson::Error, wait: 2.seconds, attempts: 10

  def perform(trade_id)
    trade = PracticeTrade.find_by(id: trade_id)
    return unless trade&.open?

    if trade.expired?
      trade.settle_if_due!(LivePrice.usd(trade.metal))
    else
      # Ran a little early: come back at the real expiry time.
      self.class.set(wait_until: trade.expires_at).perform_later(trade.id)
    end
  end
end

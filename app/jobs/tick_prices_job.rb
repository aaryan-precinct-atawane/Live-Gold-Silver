# Runs on a schedule (see config/recurring.yml) and publishes the next prices.
class TickPricesJob < ApplicationJob
  queue_as :default

  def perform
    PriceTicker.tick!
  end
end

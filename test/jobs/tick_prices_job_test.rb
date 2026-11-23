require "test_helper"

class TickPricesJobTest < ActiveJob::TestCase
  test "saves the latest gold and silver prices" do
    assert_difference -> { PriceQuote.count }, 2 do
      TickPricesJob.perform_now
    end
  end
end

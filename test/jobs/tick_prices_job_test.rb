require "test_helper"

class TickPricesJobTest < ActiveJob::TestCase
  test "publishes one quote per metal with entries" do
    assert_difference -> { PriceQuote.count }, 2 do
      TickPricesJob.perform_now
    end
  end
end

require "test_helper"

class UsdInrRateTest < ActiveSupport::TestCase
  test "returns the INR rate" do
    assert_equal BigDecimal("90.0"), UsdInrRate.new.current
  end

  test "raises HttpJson::Error on an unexpected response" do
    rate = UsdInrRate.new(fetcher: ->(_url) { { "rates" => {} } })
    assert_raises(HttpJson::Error) { rate.current }
  end
end

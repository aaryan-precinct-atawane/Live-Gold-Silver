require "test_helper"

class PricesHelperTest < ActionView::TestCase
  test "formats rupees and dollars" do
    assert_equal "₹76,500.00", inr(76_500)
    assert_equal "$2,650.40", usd(2650.4)
  end

  test "price_change shows direction, amount and percent" do
    assert_includes price_change(110.to_d, 100.to_d), "▲ 10.00 (10.00%)"
    assert_includes price_change(90.to_d, 100.to_d), "▼ 10.00 (10.00%)"
    assert_includes price_change(100.to_d, 100.to_d), "▬ 0.00 (0.00%)"
    assert_includes price_change(100.to_d, nil), "—"
  end
end

require "test_helper"

class PricesHelperTest < ActionView::TestCase
  test "formats rupees with Indian digit grouping" do
    assert_equal "₹999.00", inr(999)
    assert_equal "₹3,36,227.45", inr(336_227.45)
    assert_equal "₹1,23,45,678.90", inr(12_345_678.9)
    assert_equal "₹92.6800", inr(92.68, precision: 4)
  end

  test "formats dollars" do
    assert_equal "$3,627.83", usd(3627.83)
  end

  test "price_change shows direction, amount and percent" do
    assert_includes price_change(110.to_d, 100.to_d), "▲ 10.00 (10.00%)"
    assert_includes price_change(90.to_d, 100.to_d), "▼ 10.00 (10.00%)"
    assert_includes price_change(100.to_d, 100.to_d), "▬ 0.00 (0.00%)"
    assert_includes price_change(100.to_d, nil), "—"
  end

  test "price_change uses Indian grouping for rupees" do
    assert_includes price_change(450_000.to_d, 300_000.to_d, currency: :inr), "▲ 1,50,000.00"
  end
end

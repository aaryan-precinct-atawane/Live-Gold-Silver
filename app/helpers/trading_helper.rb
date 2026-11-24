module TradingHelper
  # "+₹1,20,000.50", "-₹500.00" or "₹0.00". Uses PricesHelper#inr for Indian grouping.
  def signed_inr(amount)
    sign = if amount.positive? then "+" elsif amount.negative? then "-" else "" end
    "#{sign}#{inr(amount.abs)}"
  end

  # CSS class for a profit (green), loss (red) or break-even (grey) amount.
  def pnl_class(amount)
    if amount.nil? || amount.zero? then "change change--flat"
    elsif amount.positive? then "change change--up"
    else "change change--down"
    end
  end

  def multiple(value)
    "#{format('%.2f', value)}×"
  end

  def close_reason_label(reason)
    { "expired" => "Expired", "manual" => "Closed by you", "stopped_out" => "Stopped out" }.fetch(reason, reason.to_s)
  end

  # Milliseconds since 1970, which JavaScript's Date understands.
  def js_time(time)
    (time.to_f * 1000).round
  end
end

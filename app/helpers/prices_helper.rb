module PricesHelper
  def inr(amount)
    number_to_currency(amount, unit: "₹", precision: 2)
  end

  def usd(amount)
    number_to_currency(amount, unit: "$", precision: 2)
  end

  # Shows how a price moved since the previous tick, e.g. "▲ 320.00 (0.42%)".
  def price_change(current, previous)
    return tag.span("—", class: "change change--flat") if previous.nil?

    diff = current - previous
    percent = previous.zero? ? 0 : diff / previous * 100

    arrow, css = if diff.positive? then [ "▲", "up" ]
    elsif diff.negative? then [ "▼", "down" ]
    else [ "▬", "flat" ]
    end

    text = "#{arrow} #{number_with_precision(diff.abs, precision: 2, delimiter: ',')} " \
           "(#{number_with_precision(percent.abs, precision: 2)}%)"
    tag.span(text, class: "change change--#{css}")
  end
end

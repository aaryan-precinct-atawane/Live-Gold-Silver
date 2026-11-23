module PricesHelper
  # Rupees with Indian digit grouping, e.g. ₹3,36,227.45 (lakh and crore style).
  def inr(amount, precision: 2)
    "₹#{indian_number(amount, precision: precision)}"
  end

  def usd(amount)
    number_to_currency(amount, unit: "$", precision: 2)
  end

  # 336227.45 -> "3,36,227.45": the last 3 digits, then groups of 2.
  def indian_number(amount, precision: 2)
    whole, fraction = format("%.#{precision}f", amount.abs).split(".")
    if whole.length > 3
      head = whole[0...-3].reverse.scan(/\d{1,2}/).join(",").reverse
      whole = "#{head},#{whole[-3..]}"
    end
    sign = amount.negative? ? "-" : ""
    [ "#{sign}#{whole}", fraction ].compact.join(".")
  end

  # Shows how a price moved since the previous tick, e.g. "▲ 320.00 (0.42%)".
  def price_change(current, previous, currency: :usd)
    return tag.span("—", class: "change change--flat") if previous.nil?

    diff = current - previous
    percent = previous.zero? ? 0 : diff / previous * 100

    arrow, css = if diff.positive? then [ "▲", "up" ]
    elsif diff.negative? then [ "▼", "down" ]
    else [ "▬", "flat" ]
    end

    amount = currency == :inr ? indian_number(diff.abs) : number_with_precision(diff.abs, precision: 2, delimiter: ",")
    text = "#{arrow} #{amount} (#{number_with_precision(percent.abs, precision: 2)}%)"
    tag.span(text, class: "change change--#{css}")
  end
end

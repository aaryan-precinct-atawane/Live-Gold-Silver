# Fetches the US dollar to Indian rupee exchange rate from Frankfurter
# (free, no API key; publishes European Central Bank reference rates once per working day).
class UsdInrRate
  API_URL = "https://api.frankfurter.dev/v1/latest?base=USD&symbols=INR".freeze

  def initialize(fetcher: HttpJson.method(:get))
    @fetcher = fetcher
  end

  # Returns how many rupees one US dollar buys, as a BigDecimal.
  def current
    rate = BigDecimal(@fetcher.call(API_URL).fetch("rates").fetch("INR").to_s)
    raise HttpJson::Error, "Frankfurter returned a non-positive USD/INR rate" unless rate.positive?

    rate
  rescue KeyError, ArgumentError, TypeError, NoMethodError => e
    raise HttpJson::Error, "Unexpected Frankfurter response: #{e.message}"
  end
end

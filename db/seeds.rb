# Sample prices so the ticker has something to cycle through right away.
# Safe to run more than once: it only adds entries for a metal that has none.
#
#   bin/rails db:seed

SAMPLE_PRICES = {
  "gold" => [
    [ 76_500.00, 2_650.40 ],
    [ 76_820.00, 2_661.10 ],
    [ 76_300.00, 2_643.75 ],
    [ 77_010.00, 2_668.20 ],
    [ 76_740.00, 2_657.90 ]
  ],
  "silver" => [
    [ 91_200.00, 31.20 ],
    [ 91_850.00, 31.45 ],
    [ 90_900.00, 31.05 ],
    [ 92_300.00, 31.62 ],
    [ 91_600.00, 31.38 ]
  ]
}.freeze

SAMPLE_PRICES.each do |metal, prices|
  next if PriceEntry.for_metal(metal).exists?

  prices.each do |price_inr, price_usd|
    PriceEntry.create!(metal: metal, price_inr: price_inr, price_usd: price_usd)
  end
  puts "Added #{prices.size} #{metal} prices."
end

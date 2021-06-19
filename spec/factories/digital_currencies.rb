FactoryBot.define do
  factory :digital_currency do
    symbol_from { "btc" }
    symbol_to { "usdt" }
    symbol { "btcusdt" }
  end
end

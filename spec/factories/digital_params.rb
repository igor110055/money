FactoryBot.define do
  factory :digital_param do
    symbol { "btcusdt" }
    deal_type { "bl" }
    param_name { "buy_interval_sec" }
    param_value { "1200" }
  end
end

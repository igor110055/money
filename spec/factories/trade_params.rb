FactoryBot.define do
  factory :trade_param do
    name { "buy_interval_sec" }
    title { "每隔几秒自动买入一次" }
    param_type { "s" }
    default_range_step { "" }
    order_num { 1 }
  end
end

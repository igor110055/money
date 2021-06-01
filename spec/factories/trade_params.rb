FactoryBot.define do
  factory :trade_param do
    name { "MyString" }
    title { "MyString" }
    param_type { "s" }
    default_range_step { "" }
    order_num { 1 }
  end
end

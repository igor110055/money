FactoryBot.define do
  factory :trade_strategy do
    symbol { "MyString" }
    deal_type { "MyString" }
    param_value { "MyString" }
    range_step { "MyString" }
    trade_param { nil }
  end
end

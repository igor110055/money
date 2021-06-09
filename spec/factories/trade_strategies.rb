FactoryBot.define do
  factory :trade_strategy do
    association :trade_param
    deal_type { "MyString" }
    param_name { "MyString" }
    param_value { "MyString" }
    range_step { "MyString" }
  end
end

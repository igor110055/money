FactoryBot.define do

  factory :property do

    name { '现金' }
    sync_code { 'cash' }
    amount { 10000.0 }
    is_hidden { false }
    is_locked { false }
    tag_list { '个人资产' }
    association :currency, :krw

    trait :twd do
      name { '台北银行' }
      sync_code { 'tbank' }
      amount { 1567.0 }
      association :currency, :twd
    end

    trait :twd_loan do
      name { '新光银行' }
      sync_code { 'xgbank' }
      amount { -50.0 }
      association :currency, :twd
    end

    trait :usd_hidden do
      name { '个人比特币' }
      sync_code { 'mybtc' }
      amount { 10000.0 }
      is_hidden { true }
      association :currency, :usd
    end

    trait :usd_locked do
      name { '私人比特币' }
      sync_code { 'pribtc' }
      amount { 10000.0 }
      is_locked { true }
      association :currency, :usd
    end

    trait :cny do
      name { '我的工商银行账户' }
      sync_code { 'icbc' }
      amount { 789.0 }
      association :currency, :cny
    end

    trait :usd do
      name { '币托比特币总值' }
      sync_code { 'bitoex_btc' }
      amount { 150.00 }
      association :currency, :usd
    end

    trait :house do
      name { '燕大星苑' }
      sync_code { 'yd_house' }
      amount { 600000.00 }
      association :currency, :cny
    end

    trait :stock do
      name { '台积电' }
      sync_code { 'taijidian' }
      amount { 300000.00 }
      association :currency, :twd
    end

    trait :btc do
      name { '个人比特币' }
      sync_code { 'my_btc' }
      amount { 2.4567 }
      association :currency, :btc
    end

    trait :usdt do
      name { 'USDT' }
      sync_code { 'usdt' }
      amount { 100.0 }
      tag_list { '170' }
      association :currency, :usdt
    end

  end

end

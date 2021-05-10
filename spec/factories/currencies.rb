FactoryBot.define do

  factory :currency do

    name { '日元' }
    code { 'JPY' }
    exchange_rate { 108.00 }

    trait :twd do
      name { '新台币' }
      code { 'TWD' }
      exchange_rate { 31.00 }
    end

    trait :cny do
      name { '人民币' }
      code { 'CNY' }
      exchange_rate { 7.0 }
    end

    trait :usd do
      name { '美元' }
      code { 'USD' }
      exchange_rate { 1.0 }
    end

    trait :krw do
      name { '韩元' }
      code { 'KRW' }
      exchange_rate { 1173.0 }
    end

    trait :btc do
      name { '比特币' }
      code { 'BTC' }
      exchange_rate { 0.00001782 }
    end

    trait :usdt do
      name { '泰达币' }
      code { 'USDT' }
      exchange_rate { 1.0001 }
    end

    trait :eth do
      name { '以太坊' }
      code { 'ETH' }
      exchange_rate { 0.00029119 }
    end

    trait :doge do
      name { '狗狗币' }
      code { 'DOGE' }
      exchange_rate { 2.10216523 }
    end

  end

end

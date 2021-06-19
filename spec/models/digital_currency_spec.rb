require 'rails_helper'

RSpec.describe '模型测试[DigitalCurrency]', type: :model do

  describe '基本验证' do

    specify '交易对若无symbol_from和symbol_to则无法建立' do
      expect_field_value_not_be_nil :digital_currency, :symbol_from, $digital_currency_symbol_from_blank_err
      expect_field_value_not_be_nil :digital_currency, :symbol_to, $digital_currency_symbol_to_blank_err
    end

    specify '能根据输入的值建构正确的交易对名' do
      dc = build(:digital_currency, symbol_from: 'eth', symbol_to: 'btc')
      dc.save
      expect(dc.symbol).to eq 'ethbtc'
    end

    specify '交易对名不可以重复' do
      dc1 = build(:digital_currency, symbol_from: 'eth', symbol_to: 'btc')
      dc1.save
      dc2 = build(:digital_currency, symbol_from: 'eth', symbol_to: 'btc')
      dc2.save
      expect(dc2).not_to be_valid
    end

  end

end

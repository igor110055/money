require 'rails_helper'

RSpec.describe '模型测试[DigitalCurrency]', type: :model do

  describe '基本验证' do

    specify '交易对若无symbol_from和symbol_to则无法建立' do
      expect_field_value_not_be_nil :digital_currency, :symbol_from, $digital_currency_symbol_from_blank_err
      expect_field_value_not_be_nil :digital_currency, :symbol_to, $digital_currency_symbol_to_blank_err
    end

  end

end

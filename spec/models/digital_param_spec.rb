require 'rails_helper'

RSpec.describe '模型测试[DigitalParam]', type: :model do

  describe '基本验证' do

    let!(:trade_param) { create(:trade_param, name: 'buy_interval_sec') }

    specify '若无交易对买卖别参数名和参数值则无法建立' do
      expect_field_value_not_be_nil :digital_param, :symbol, $digital_param_symbol_blank_err
      expect_field_value_not_be_nil :digital_param, :deal_type, $digital_param_deal_type_blank_err
      expect_field_value_not_be_nil :digital_param, :param_name, $digital_param_name_blank_err
      expect_field_value_not_be_nil :digital_param, :param_value, $digital_param_value_blank_err
    end

    specify '交易对买卖别和参数名不可以重复' do
      dp1 = build(:digital_param, symbol: 'btcusdt', deal_type: 'bl', param_name: 'buy_interval_sec', param_value: '1200')
      dp1.save
      dp2 = build(:digital_param, symbol: 'btcusdt', deal_type: 'bl', param_name: 'buy_interval_sec', param_value: '600')
      dp2.save
      expect(dp2).not_to be_valid
    end

  end

end

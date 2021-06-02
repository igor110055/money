require 'rails_helper'

RSpec.describe '模型测试[TradeStrategy]', type: :model do

  describe '基本验证' do

    specify '交易策略必须若无交易对.买卖类型.参数值.参数ID则无法建立' do
      expect_field_value_not_be_nil :trade_strategy, :symbol, $trade_strategy_symbol_blank_err
      expect_field_value_not_be_nil :trade_strategy, :deal_type, $trade_strategy_deal_type_blank_err
      expect_field_value_not_be_nil :trade_strategy, :param_value, $trade_strategy_param_value_blank_err
      expect_field_value_not_be_nil :trade_strategy, :trade_param_id, $trade_strategy_trade_param_id_blank_err
    end

  end

end

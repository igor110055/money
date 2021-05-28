require 'rails_helper'

RSpec.describe '模型测试[TradeParam]', type: :model do

  describe '基本验证' do

    specify '交易参数若无名称和标题则无法建立' do
      expect_field_value_not_be_nil :trade_param, :name, $trade_param_name_blank_err
      expect_field_value_not_be_nil :trade_param, :title, $trade_param_title_blank_err
    end

  end

end

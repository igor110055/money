require 'rails_helper'

RSpec.describe '模型测试[TradeParam]', type: :model do

  describe '基本验证' do

    specify '交易参数若无名称和标题则无法建立' do
      expect_field_value_not_be_nil :trade_param, :name, $trade_param_name_blank_err
      expect_field_value_not_be_nil :trade_param, :title, $trade_param_title_blank_err
    end

    specify '交易参数若无参数类型则无法建立' do
      expect_field_value_not_be_nil :trade_param, :param_type, $trade_param_type_blank_err
    end

    specify '交易参数的排序号必须为大于零的数' do
      expect_field_value_must_greater_than_zero :trade_param, :order_num, $trade_param_order_num_format_err
    end

  end

end

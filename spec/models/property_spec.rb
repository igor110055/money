require 'rails_helper'

RSpec.describe '模型测试[Property]', type: :model do

  fixtures :currencies
  let!(:ori_twd_rate) { currencies(:twd).exchange_rate.to_f }
  let!(:ori_cny_rate) { currencies(:cny).exchange_rate.to_f }

  describe '基本验证' do

    specify '资产若无名称和金额则无法新建并能显示错误讯息' do
      expect_field_value_not_be_nil :property, :name, $property_name_blank_err
      expect_field_value_not_be_nil :property, :amount, $property_amount_blank_err
      expect_field_value_not_be_nil :property, 'name,amount'
    end

    specify '资产名称不能超过30个字元并能显示错误讯息' do
      expect_field_value_not_too_long :property, :name, $property_name_maxlength,  $property_name_len_err
    end

    specify '资产金额非数字形态能显示错误讯息' do
      expect_field_value_must_be_a_number :property, :amount, $property_amount_nan_err
    end

    specify '资产若没有关联的货币种类则无法新建' do
      property = build(:property, currency: nil)
      expect(property).not_to be_valid
    end

    specify '资产若没有关联的货币种类则无法更新' do
      property = create(:property)
      property.currency = nil
      property.save
      expect(property.errors.messages[:currency]).not_to be_blank
    end

    specify '每笔资产的金额能换算成其他币种' do
      p = create(:property, amount: 100.0, currency: currencies(:twd))
      # 查不到该币别则返回原值
      expect(p.amount_to(:unknow)).to eq 100.0
      # 从自身的币别(台币)转换成人民币和美元
      trate = currencies(:twd).exchange_rate.to_f
      crate = currencies(:cny).exchange_rate.to_f
      expect(p.amount_to(:cny).to_i).to eq (100.0*(crate/trate)).to_i
      expect(p.amount_to(:usd).to_i).to eq (100.0*(1.0/trate)).to_i
    end

    specify '同步更新码必须是唯一的否则会提示错误讯息' do
      p1 = create(:property, sync_code: 'cash_10')
      p2 = create(:property)
      p2.sync_code = 'cash_10'
      p2.save
      expect(p2.errors.messages).not_to be_blank
    end

  end

  describe '进阶验证' do

    before { create_different_currency_properties }

    specify '资产附加隐藏属性且一般列表中看不到它' do
      property = @ps[0]
      property.set_as_hidden
      expect(property.reload).to be_hidden
      expect(Property.all_visible).not_to include property
    end

    specify '资产模型新增不可删除属性以免某些使用的资产因删除而导致系统无法使用' do
      property = @ps[0]
      property.set_as_locked
      expect(property.reload).to be_locked
    end

    specify '资产模型能计算各资产占总资产比例(正负资产分开)' do
      # 计算正资产占比
      pp = @ps[0]
      p_total = property_total_value_to :twd, nil, only_positive: true
      pp_pro = (pp.amount_to.to_f/p_total.to_f)*100.0
    end

  end

end

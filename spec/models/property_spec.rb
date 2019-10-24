require 'rails_helper'

RSpec.describe '模型测试(Property)', type: :model do

  specify '资产若无名称和金额则无法新建并能显示错误讯息' do
    expect_field_value_not_be_nil :property, :name, $property_name_blank_err
    expect_field_value_not_be_nil :property, :amount, $property_amount_blank_err
    expect_field_value_not_be_nil :property, 'name,amount'
  end

  specify '资产名称不能超过30个字元并能显示错误讯息' do
    expect_field_value_not_too_long :property, :name, $property_name_maxlength,  $property_name_len_err
  end

  specify '资产金额非数字形态能显示错误讯息' do
    expect_field_value_must_be_numeric :property, :amount, $property_amount_nan_err
  end

  specify '#99[模型层]资产若没有关联的货币种类则无法新建' do
    property = build(:property, currency: nil)
    expect(property).not_to be_valid
  end

  specify '#100[模型层]资产若没有关联的货币种类则无法更新' do
    property = create(:property)
    property.currency = nil
    property.save
    expect(property.errors.messages[:currency]).not_to be_blank
  end

  specify '#101[模型层]每笔资产的金额能换算成其他币种' do
    twd = create(:currency, :twd, exchange_rate: 31.0)
    cny = create(:currency, :cny, exchange_rate: 7.0)
    usd = create(:currency, :usd, exchange_rate: 1.0)
    p = create(:property, amount: 100.0, currency: twd)
    # 从自身的币别(台币)转换成人民币和美元
    expect(p.amount_to(:cny)).to eq 100.0*(7.0/31.0)
    expect(p.amount_to(:usd)).to eq 100.0*(1.0/31.0)
    # 查不到该币别则返回原值
    expect(p.amount_to(:unknow)).to eq 100.0
  end

  # specify '#102[模型层]资产能以新台币或其他币种结算所有资产的总值' do
  #   pt = create(:property)
  #   pc = create(:property, :cny)
  #   pu = create(:property, :usd)
  #   at = pt.amount
  #   ac = pc.amount
  #   au = pu.amount
  #   et = pt.currency.exchange_rate # 美元兑台币汇率
  #   ec = pc.currency.exchange_rate # 美元兑人民币汇率
  #   eu = 1.0 # 美元兑美元汇率
  #   total_twd_value = Property.sum
  #   total_cny_value = Property.sum :cny
  #   total_usd_value = Property.sum :usd
  #   expect(total_twd_value.to_i).to eq
  # end

end

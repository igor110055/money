require 'rails_helper'

RSpec.describe '连外测试(Currencies)', type: :system do

  before do
    visit login_path
    fill_in 'pincode', with: $pincode
    find('#login').click
  end

  describe '列表显示' do

    before do
      visit currencies_path
    end

    specify '#127[系统层]在货币列表中点击更新匯率能更新比特币的汇率值' do
      # 合并于 #144[系统层]更新比特币汇率之前能先更新USDT的汇率 以节省测试时间
    end

    specify '#129[系统层]在货币列表中点击更新匯率能更新所有法币的汇率值' do
      # 合并于 #144[系统层]更新比特币汇率之前能先更新USDT的汇率 以节省测试时间
    end

    specify '#144[系统层]更新比特币汇率之前能先更新USDT的汇率' do
      find('#update_all_exchange_rates').click
      expect(page).to have_selector '.alert-notice', text: /#{$update_usdt_price_ok}/
      expect(page).to have_selector '.alert-notice', text: /#{$update_btc_price_ok}/
      expect(page).to have_selector '.alert-notice', text: /#{$n_legal_exchange_rates_updated_ok}/
    end

  end

end

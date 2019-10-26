require 'rails_helper'

RSpec.describe '系统测试(Properties)', type: :system do

  fixtures :currencies

  before do
    visit login_path
    fill_in 'pincode', with: $pincode
    find('#login').click
  end

  describe '列表显示' do

    specify '#108[系统层]能在资产列表中显示包含利息的资产总净值' do
      create_different_currency_properties
      # 资产净值 = 原始资产总值 + 资产的利息总值
      properties_net_value = (property_total_value_to(:twd) + property_total_lixi_to(:twd)).to_i
      visit properties_path
      expect(page).to have_selector '#properties_net_value' , text: properties_net_value
    end

  end

  describe '新增资产' do

    before do
      visit properties_path
      find('#add_new_property').click
    end

    describe '成功用例' do

      specify '能通过表单新增一笔资产记录' do
        visit properties_path
        find('#add_new_property').click
        fill_in 'property[name]', with: '我的工商银行账户'
        fill_in 'property[amount]', with: 99.9999
        select '人民币', from: 'property[currency_id]'
        find('#create_new_property').click
        expect(page).to have_content '我的工商银行账户'
        expect(page).to have_content 99.99
        expect(page).to have_selector '.alert-notice'
      end

    end

    describe '失败用例' do

      specify '当资产没有名称时无法新建且显示错误讯息' do
        fill_in 'property[name]', with: ''
        find('#create_new_property').click
        expect(page).to have_content $property_name_blank_err
      end

      specify '当资产没有金额时无法新建且显示错误讯息' do
        fill_in 'property[amount]', with: nil
        find('#create_new_property').click
        expect(page).to have_content $property_amount_blank_err
      end

      specify '当资产名称过长时无法新建且显示错误讯息' do
        fill_in 'property[name]', with: 'a'*($property_name_maxlength+1)
        find('#create_new_property').click
        expect(page).to have_content $property_name_len_err
      end

      specify '当资产金额不为数字时无法新建且显示错误讯息' do
        fill_in 'property[amount]', with: 'abcd'
        find('#create_new_property').click
        expect(page).to have_content $property_amount_nan_err
      end

    end

  end

  describe '修改与删除资产' do

    let!(:property) { create(:property) }
    before do
      visit properties_path
      click_on property.name
    end

    describe '成功用例' do

      specify '能通过表单修改资产的名称' do
        fill_in 'property[name]', with: '我的中国银行账户'
        find('#update_property').click
        expect(page).to have_content '我的中国银行账户'
        expect(page).to have_selector '.alert-notice'
      end

      specify '能通过表单修改资产的金额' do
        fill_in 'property[amount]', with: 1000.9865
        find('#update_property').click
        expect(page).to have_content 1000.98
        expect(page).not_to have_content 1000.9865
        expect(page).to have_selector '.alert-notice'
        click_on property.name
        fill_in 'property[amount]', with: -100.8899
        find('#update_property').click
        expect(page).to have_content -100.88
      end

      specify '能通过表单删除一笔资产记录' do
        find('#delete_property').click
        expect(page).not_to have_content property.name
        expect(page).to have_selector '.alert-notice'
      end

    end

    describe '失败用例' do

      specify '当资产没有名称时无法更新且显示错误讯息' do
        fill_in 'property[name]', with: ''
        find('#update_property').click
        expect(page).to have_content $property_name_blank_err
      end

      specify '当资产名称过长时无法更新且显示错误讯息' do
        fill_in 'property[name]', with: 'a'*($property_name_maxlength+1)
        find('#update_property').click
        expect(page).to have_content $property_name_len_err
      end

      specify '当资产没有金额时无法更新且显示错误讯息' do
        fill_in 'property[amount]', with: nil
        find('#update_property').click
        expect(page).to have_content $property_amount_blank_err
      end

      specify '当资产金额不为数字时无法更新且显示错误讯息' do
        fill_in 'property[amount]', with: 'abcd'
        find('#update_property').click
        expect(page).to have_content $property_amount_nan_err
      end

    end

  end

end

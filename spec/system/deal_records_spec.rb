# require 'rails_helper'
#
# RSpec.describe '系统测试[DealRecords]', type: :system do
#
#   describe '管理员登入' do
#
#     let!(:deal_record) { create(:deal_record) }
#     let!(:usdt) { create(:property, :usdt) }
#
#     before { login_as_admin }
#
#     specify '能更新交易记录属性' do
#       visit edit_deal_record_path(deal_record)
#       fill_in 'deal_record[purpose]', with: '买新的电脑'
#       fill_in 'deal_record[earn_limit]', with: 9000
#       fill_in 'deal_record[loss_limit]', with: 500
#       find('#update_deal_record').click
#       expect(page).to have_selector '.alert-notice'
#     end
#
#     specify '能通过表单删除一笔交易记录' do
#       visit edit_deal_record_path(deal_record)
#       find('#delete_deal_record').click
#       expect(page).not_to have_content deal_record.symbol
#       expect(page).to have_selector '.alert-notice'
#     end
#
#     specify '新增下单链接并能选择买卖种类及显示目前仓位大小' do
#       visit place_order_form_path
#       expect(page.html).to include 'buy-limit'
#       expect(page.html).to include 'sell-limit'
#       expect(page).to have_content DealRecord.btc_level
#     end
#
#     specify '下单时输入数量并按下试算能显示成交后的仓位最后能成功送出订单' do
#       visit place_order_form_path
#       expect(page).to have_content DealRecord.usdt_amount
#     end
#
#   end
#
# end

require 'rails_helper'

RSpec.describe '连外测试[Currencies]', type: :system do

  fixtures :currencies

  before { login_as_admin }

  describe '列表显示' do

    before do
      visit currencies_path
    end

    # specify '在货币列表中点击更新匯率能更新比特币的汇率值' do
    # end

  end

end

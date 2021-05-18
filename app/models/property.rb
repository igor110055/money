require 'net/http'

class Property < ApplicationRecord

  include ApplicationHelper

  acts_as_taggable
  belongs_to :currency
  has_one :interest
  has_one :item

  after_create :update_records

  validates \
    :name,
      presence: {
        message: $property_name_blank_err },
      length: {
        maximum: $property_name_maxlength,
        message: $property_name_len_err }

  validates \
    :amount,
      presence: {
        message: $property_amount_blank_err } ,
      numericality: {
        message: $property_amount_nan_err }

  # 资产能以新台币或其他币种结算所有资产的总值
  def self.value( target_code = :twd, options = {} )
    result = 0
    all.each do |p|
      (next if p.hidden?) if !options[:include_hidden]
      (next if p.negative?) if options[:only_positive]
      (next if p.positive?) if options[:only_negative]
      if options[:btc_price]
        result += p.amount_to(target_code,options[:btc_price])
      else
        result += p.amount_to(target_code)
      end
    end
    return result
  end

  # 资产能以新台币或其他币种结算所有资产的利息总值
  def self.lixi( target_code = :twd, options = {} )
    result = 0
    all.each do |p|
      (next if p.hidden?) if !options[:include_hidden]
      result += p.lixi(target_code)
    end
    return result
  end

  # 资产能以新台币或其他币种结算所有资产包含利息的净值
  def self.net_value( target_code = :twd, options = {} )
    value(target_code,options) # + lixi(target_code,options) 默认每项贷款数值已包含利息,故无须重复抵扣
  end

  # 资产列表能显示3月底以来资产净值平均月增减额度
  def self.net_growth_ave_month( target_code = :twd, options = {} )
    if target_code == :twd
      start_value = $net_start_value
    elsif target_code == :cny
      start_value = $net_start_value * self.new.twd_to_cny
    end
    (net_value(target_code,options)-start_value)/pass_days*30
  end

  # 取出所有数据集并按照等值台币由大到小排序
  def self.all_sort( is_admin = false )
    scope = is_admin ? 'all' : 'all_visible'
    eval("#{scope}.sort_by{|p| p.amount_to}.reverse")
  end

  # 只回传所有非隐藏的资产
  def self.all_visible
    all.select {|p| !p.hidden? }
  end

  # 清空某个资产的金额
  def self.clear_amount( property_id )
    find(property_id).update_attribute(:amount,0)
  end

  # 贷款(含利息)的总额
  def self.total_loan_lixi
    (Property.tagged_with('贷款').sum {|p| p.amount_to(:twd)}).abs
  end

  # 贷款(含利息)的总额
  def self.loan_lixi( to_date = Date.today )
    result = 0
    if get_huobi_acc_id == '170'
      tag = '家庭贷款'
    elsif get_huobi_acc_id == '135'
      tag = '个人贷款'
    end
    result = Property.tagged_with(tag).sum {|p| p.amount_to(:twd,0,to_date)} if tag
    return result.abs
  end

  # 贷款(含利息)的总额从台币换算成泰达币
  def self.total_loan_lixi_usdt
    total_loan_lixi*(new.twd_to_usdt)
  end

  def self.get_invest_param_from( file_path, index, to_number = true )
    value = File.read(file_path).split(' ')[index]
    if to_number
      return value.to_f
    else
      return value
    end
  end

  # 数字货币总资产换算成比特币
  def self.invest_to_btc( is_admin = false )
    # 读取交易列表上的交易总额与比特币总数以求平均成本
    cost1 = get_invest_param_from($auto_invest_params_path,25)
    amount1 = get_invest_param_from($auto_invest_params_path,26)
    cost2 = get_invest_param_from($auto_invest_params_path2,25)
    amount2 = get_invest_param_from($auto_invest_params_path2,26)
    record_cost = cost1 + cost2
    record_amount = amount1 + amount2
    real_ave_cost = record_amount > 0 ? record_cost/record_amount : 0
    # 处理交易列表的已实现损益和未实现损益
    sell_profit1, unsell_profit1, ave_sec_profit1, real_p_24h1, trezor_cost1, trezor_amount1 = get_invest_param_from($auto_invest_params_path,28,false).split(':')
    sell_profit2, unsell_profit2, ave_sec_profit2, real_p_24h2, trezor_cost2, trezor_amount2 = get_invest_param_from($auto_invest_params_path2,28,false).split(':')
    total_real_profit = sell_profit1.to_f + sell_profit2.to_f
    total_unsell_profit = unsell_profit1.to_f + unsell_profit2.to_f
    ave_hour_profit = (ave_sec_profit1.to_f + ave_sec_profit2.to_f)*60*60
    total_real_p_24h = real_p_24h1.to_i + real_p_24h2.to_i
    # 冷钱包的成本与均价
    trezor_cost = trezor_cost1.to_f+trezor_cost2.to_f
    trezor_amount = trezor_amount1.to_f+trezor_amount2.to_f
    trezor_ave_cost = trezor_cost/trezor_amount
    # 所有比特币均价
    total_ave_cost = (record_cost+trezor_cost)/(record_amount+trezor_amount)
    # 现价与均价的比率(利率)
    price_now = new.get_btc_price
    price_p = real_ave_cost > 0 ? (price_now/real_ave_cost-1)*100 : 0
    # 以比特币计算的总资产值
    p_btc = btc_records.sum {|p| p.amount}
    p_eth = Property.tagged_with('以太坊').sum {|p| p.amount}
    p_trezor = Property.tagged_with('冷钱包').sum {|p| p.amount}
    p_trezor_twd = Property.tagged_with('冷钱包').sum {|p| p.amount_to(:twd)}
    p_ex = Property.tagged_with('交易所').sum {|p| p.amount_to(:twd)}
    p_mine_earn = Property.tagged_with('矿场').sum {|p| p.amount_to(:twd)}
    p_alipay = Property.tagged_with('支付宝').sum {|p| p.amount_to(:twd)}
    flow_assets_twd = Property.total_flow_assets_twd # 流动性资产总值
    eq_btc = flow_assets_twd*(new.twd_to_btc)
    # 矿机占流动资产比例
    flow_plus_mine_twd = flow_assets_twd+mine_costs_twd
    mine_p = mine_costs_twd/flow_plus_mine_twd*100
    # 矿机可投资额度
    mine_buy_cny = (flow_plus_mine_twd*$mine_buy_limit-mine_costs_twd)*(new.twd_to_cny)
    # 计算交易所和矿场持仓的实际比例
    btc_ex = btc_in_huobi_records # 交易所持仓的数据集
    if eq_btc > 0
      btc_ex_p = (btc_in_huobi_records.sum {|p| p.amount})/eq_btc*100
      ex_p = p_ex/flow_assets_twd*100
      mine_earn_p = p_mine_earn/flow_assets_twd*100
      alipay_p = p_alipay/flow_assets_twd*100
    else
      btc_ex_p = 0
      ex_p = 0
      mine_earn_p = 0
      alipay_p = 0
    end
    # 计算可投资金的实际比例
    investable = total_investable_fund_records # 所有可投资金数据集
    investable_cny = investable.sum {|p| p.amount_to(:cny)}
    if eq_btc > 0
      # 加上矿机成本计算占比
      capital_p = (investable.sum {|p| p.amount_to(:twd)})/flow_plus_mine_twd*100
    else
      capital_p = 0
    end
    # 如果梭哈均价
    sim_cost = investable.sum {|p| p.amount_to(:usdt)}
    sim_amount = sim_cost/price_now # 所有可投资金全部购买BTC
    sim_ave_cost = (record_cost+trezor_cost+sim_cost)/(record_amount+trezor_amount+sim_amount)
    # 比特币每1个百分点对应多少人民币
    begin
      btc_p = btc_level(nil,true)
      eth_p = eth_level(nil,true)
      one_btc2cny = p_btc*(new.btc_to_cny)/btc_p
    rescue
      btc_p = eth_p = one_btc2cny = 0
    end
    # 计算 ①冷钱包购房(85%) ②交易所赚钱(5%) ③余额宝补仓(10%) 的实际比例
    begin
      trezor_p = p_trezor_twd/flow_assets_twd*100
      huobi_p = (Property.tagged_with('交易所').sum {|p| p.amount_to(:btc)})/eq_btc*100
      yuebao_p = (Property.tagged_with('支付宝').sum {|p| p.amount_to(:btc)})/eq_btc*100
    rescue
      trezor_p = huobi_p = yuebao_p = 0
    end
    if is_admin
      return p_btc, eq_btc, btc_p, eth_p, sim_ave_cost, real_ave_cost, trezor_ave_cost, total_ave_cost, price_p, one_btc2cny, total_real_profit.to_i.to_s + ' ', total_unsell_profit.to_i.to_s + ' ', ave_hour_profit.to_i.to_s + ' ', total_real_p_24h.to_s + ' ', trezor_p, huobi_p, yuebao_p, capital_p, btc_ex_p, investable_cny, p_eth, ex_p, mine_p, mine_buy_cny, mine_earn_p, alipay_p, p_trezor_twd, p_alipay, p_ex, p_mine_earn, flow_assets_twd, flow_plus_mine_twd
    else
      p_fbtc = Property.tagged_with('家庭比特币').sum {|p| p.amount_to(:btc)}
      p_finv = Property.tagged_with('家庭投资').sum {|p| p.amount_to(:btc)}
      if p_finv > 0
        p_fbtc_finv = p_fbtc/p_finv*100
      else
        p_fbtc_finv = 0
      end
      return p_fbtc, p_finv.floor(8), p_fbtc_finv, 0, sim_ave_cost, real_ave_cost, trezor_ave_cost, total_ave_cost, price_p, one_btc2cny, '', '', '', '', trezor_p, huobi_p, yuebao_p, capital_p, btc_ex_p, investable_cny, p_eth, ex_p, mine_p, mine_buy_cny, mine_earn_p, alipay_p, p_trezor_twd, p_alipay, p_ex, p_mine_earn, flow_assets_twd, flow_plus_mine_twd
    end
  end

  # 比特币价值与法币价值的比例
  def self.btc_legal_ratio
    btc_twd = (btc_records.sum {|p| p.amount_to(:twd)})
    legal_twd = (Property.tagged_with('法币').sum {|p| p.amount_to(:twd)})
    usdt_twd = (Property.tagged_with('泰达币').sum {|p| p.amount_to(:twd)})
    return btc_twd/(legal_twd+usdt_twd)
  end

  # 比特币的总成本
  def self.btc_total_cost_twd
    # 比特币的总成本 = 总贷款 - 还没购买比特币的剩余可投资资金
    result = total_loan_lixi - total_investable_fund_records_twd
    if result > 0
      return result
    else
      return 0.0001
    end
  end

  # 比特币的总成本从台币换算成泰达币
  def self.btc_total_cost_usdt
    btc_total_cost_twd*(new.twd_to_usdt)
  end

  # 冷钱包的总成本
  def self.trezor_total_cost_twd
    total_loan_lixi - (Property.tagged_with('短线').sum {|p| p.amount_to(:twd)})
  end

  # 冷钱包的总成本从台币换算成泰达币
  def self.trezor_total_cost_usdt
     trezor_total_cost_twd*(new.twd_to_usdt)
  end

  # 比特币资料集
  def self.btc_records
    Property.tagged_with('比特币')
  end

  # 以太坊资料集
  def self.eth_records
    Property.tagged_with('以太坊')
  end

  # 比特币的总数
  def self.total_btc_amount
    btc_records.sum {|p| p.amount}
  end

  # 以太坊的总数
  def self.total_eth_amount
    eth_records.sum {|p| p.amount}
  end

  # 比特币数量/比特币总数
  def self.btc_amount
    total_btc_amount
  end

  # 比特币数量/比特币总数
  def self.btc_amount_of_flow_assets
    result = 0
    flow_assets_records.each do |p|
      result += p.amount if p.currency.code == 'BTC'
    end
    return result
  end

  # 计算比特币的成本均价
  def self.btc_ave_cost
    if btc_records.size > 0
      return btc_total_cost_usdt/total_btc_amount
    else
      return 0
    end
  end

  # 计算现价要大于多少能开始获利
  def self.begin_profit_price
    btc_ave_cost
  end

  # 交易所持仓的数据集
  def self.btc_in_huobi_records
    result = []
    ps = Property.tagged_with('交易所')
    ps.each do |p|
      result << p if p.currency.code == 'BTC'
    end
    return result
  end

  # 流动性资产总值数据集
  def self.flow_assets_records
    new.get_properties_from_tags($link_to_flow_assets_list_tags,nil,$link_to_flow_assets_list_mode)
  end

  # 流动性资产总值台币现值
  def self.flow_assets_twd
    flow_assets_records.sum {|p| p.amount_to(:twd)}
  end

  # 流动性资产总值比特币现值
  def self.flow_assets_btc
    flow_assets_records.sum {|p| p.amount_to(:btc)}
  end

  # 跨账号流动性资产总值台币现值
  def self.total_flow_assets_records
    new.get_properties_from_tags($total_flow_assets_tags,nil,'a')
  end

  # 跨账号流动性资产总值台币现值
  def self.total_flow_assets_twd( btc_price = nil )
    if btc_price
      total_flow_assets_records.sum {|p| p.amount_to(:twd,btc_price)}
    else
      total_flow_assets_records.sum {|p| p.amount_to(:twd)}
    end
  end

  # 跨账号流动性资产总值USDT现值
  def self.total_flow_assets_usdt( btc_price = nil )
    if btc_price
      total_flow_assets_records.sum {|p| p.amount_to(:usdt,btc_price)}
    else
      total_flow_assets_records.sum {|p| p.amount_to(:usdt)}
    end
  end

  # 该账号BTC数据集
  def self.acc_btc_records
    result = []
    flow_assets_records.each do |p|
      result << p if p.currency.code == 'BTC'
    end
    return result
  end

  # 该账号BTC数量
  def self.acc_btc_amount
    acc_btc_records.sum {|p| p.amount}
  end

  # 所有可投资金数据集
  def self.investable_fund_records
    result = []
    flow_assets_records.each do |p|
      result << p if p.currency.code != 'BTC'
    end
    return result
  end

  # 账号范围内可投资金台币现值
  def self.investable_fund_records_twd
    investable_fund_records.sum {|p| p.amount_to(:twd)}
  end

  # 所有可投资金台币现值
  def self.investable_fund_records_cny
    investable_fund_records.sum {|p| p.amount_to(:cny)}
  end

  # 跨账号所有应急的现值
  def self.total_life_fund_records
    Property.tagged_with('应急')
  end

  # 所有应急的人民币现值
  def self.total_life_fund_records_cny
    total_life_fund_records.sum {|p| p.amount_to(:cny)}
  end

  # 跨账号所有买矿机资金的现值
  def self.buy_mine_fund_records
    Property.tagged_with('矿机基金')
  end

  # 买矿机资金的人民币现值
  def self.buy_mine_fund_records_cny
    buy_mine_fund_records.sum {|p| p.amount_to(:cny)}
  end

  # 所有应急的人民币现值
  def self.total_life_fund_records_cny
    total_life_fund_records.sum {|p| p.amount_to(:cny)}
  end

  # 狗狗币的现值
  def self.doge_records
    Property.tagged_with('狗狗币')
  end

  # 狗狗币的人民币现值
  def self.doge_records_cny
    doge_records.sum {|p| p.amount_to(:cny)}
  end

  # UNI币的现值
  def self.uni_records
    Property.tagged_with('UNI')
  end

  # UNI币的人民币现值
  def self.uni_records_cny
    uni_records.sum {|p| p.amount_to(:cny)}
  end

  # 数字货币持仓的现值
  def self.hold_shares_records
    Property.tagged_with('持币')
  end

  # 数字货币持仓的人民币现值
  def self.hold_shares_records_cny
    hold_shares_records.sum {|p| p.amount_to(:cny)}
  end

  # 数字货币持仓的现值
  def self.bank_records
    Property.tagged_with('银行')
  end

  # 数字货币持仓的人民币现值
  def self.bank_records_cny
    bank_records.sum {|p| p.amount_to(:cny)}
  end

  # 跨账号所有可投资金台币现值
  def self.total_investable_fund_records
    Property.tagged_with('可投资金')
  end

  # 跨账号所有可投资金台币现值
  def self.total_investable_fund_records_twd
    total_investable_fund_records.sum {|p| p.amount_to(:twd)}
  end

  # 跨账号所有可投资金USDT现值
  def self.total_investable_fund_records_usdt
    total_investable_fund_records.sum {|p| p.amount_to(:usdt)}
  end

  # 计算冷钱包的成本均价
  def self.trezor_ave_cost
    ps = Property.tagged_with('冷钱包')
    if ps.size > 0
      return trezor_total_cost_usdt/(ps.sum {|p| p.amount})
    else
      return 0
    end
  end

  # 计算比特币过去每月的获利率
  def self.ave_month_growth_rate
    ps = Property.tagged_with('比特币')
    if ps.size > 0
      cost = btc_total_cost_twd
      months = pass_days.to_i/30
      if months > 0
        begin
          return ((1+((ps.sum {|p| p.amount_to(:twd)})-cost)/cost)**(1.0/months)-1)*100
        rescue
          return 0
        end
      else
        return 0
      end
    else
      return 0
    end
  end

  # 某个标签资产目前的值
  def self.tag_value_twd( tag )
    ps = Property.tagged_with(tag)
    if ps.size > 0
      return ps.sum {|p| p.amount_to(:twd)}
    else
      return 0
    end
  end

  # 冷钱包目前的值
  def self.trezor_value_twd
    tag_value_twd '冷钱包'
  end

  # 比特币目前的值
  def self.btc_value_twd( btc_price = nil )
    ps = btc_records
    if ps.size > 0
      if btc_price
        return ps.sum {|p| p.amount_to(:twd,btc_price)}
      else
        return ps.sum {|p| p.amount_to(:twd)}
      end
    else
      return 0
    end
  end

  # 以太坊目前的值
  def self.eth_value_twd( eth_price = nil )
    ps = eth_records
    if ps.size > 0
      if eth_price
        return ps.sum {|p| p.amount_to(:twd,eth_price)}
      else
        return ps.sum {|p| p.amount_to(:twd)}
      end
    else
      return 0
    end
  end

  # BTC预估年化利率
  def self.cal_year_profit_p
    if ave_month_growth_rate > 0
      value = (1+ave_month_growth_rate.to_f/100)**12
      value = 10 if value >= 10
      return value
    else
      return 1
    end
  end

  # 计算冷钱包下一年收益
  def self.cal_year_profit( br = "\n" )
    t2c = self.new.twd_to_cny
    year_profit_p = cal_year_profit_p
    profit_p_value = year_profit_p-1
    btc_value_of_twd = btc_value_twd
    year_goal = (btc_value_of_twd*year_profit_p).to_i
    year_goal_cny = (year_goal*t2c).to_i
    year_profit = (btc_value_of_twd*profit_p_value).to_i
    year_profit_cny = (year_profit*t2c).to_i
    return "平均月化利率：#{format("%.2f", ave_month_growth_rate)}%" + br + "预估年化利率：#{format("%.2f", profit_p_value*100)}%" + br + "比特币年目标：#{year_goal}(¥#{year_goal_cny})" + br + "比特币年获利：#{year_profit}(¥#{year_profit_cny})" + br + "平均每月获利：#{year_profit/12}(¥#{(year_profit_cny/12).to_i})"
  end

  # 计算矿机总成本
  def self.mine_costs_twd
    ($mine_ori_cost+$mine_other_cost)*(new.cny_to_twd)
  end

  # 回传BTC总仓位值 = 比特币资产总值/流动性资产总值
  def self.btc_level( btc_price = nil, include_mine_cost = false )
    if include_mine_cost
      btc_value_twd(btc_price)/(total_flow_assets_twd(btc_price)+mine_costs_twd)*100
    else
      btc_value_twd(btc_price)/total_flow_assets_twd(btc_price)*100
    end
  end

  # 回传ETH总仓位值 = 以太坊资产总值/流动性资产总值
  def self.eth_level( btc_price = nil, include_mine_cost = false )
    if include_mine_cost
      eth_value_twd(nil)/(total_flow_assets_twd(btc_price)+mine_costs_twd)*100
    else
      eth_value_twd(nil)/total_flow_assets_twd(btc_price)*100
    end
  end

  # 要写入记录列表的值
  def record_value
    amount_to(:twd).to_i
  end

  # 计算贷款利息
  def lixi( target_code = :twd, to_date = Date.today )
    interest ? \
      (amount * (interest.rate.to_f/100/365) * \
      (to_date-interest.start_date).to_i) * \
      (target_rate(target_code)/currency.exchange_rate) : 0
  end

  # 将此资产设置为隐藏资产
  def set_as_hidden
    update_attribute(:is_hidden, true)
  end

  # 将此资产设置为不可删除资产
  def set_as_locked
    update_attribute(:is_locked, true)
  end

  # 回传此资产是否为隐藏资产
  def hidden?
    is_hidden
  end

  # 回传此资产是否为不可删除资产
  def locked?
    is_locked
  end

  # 除了数字资产以小数点8位显示外其余为小数点2位
  def value
    to_amount(amount,currency.is_digital?)
  end

  # 资产金额是否为正值
  def positive?
    amount >= 0 ? true : false
  end

  # 资产金额是否为负值
  def negative?
    amount < 0 ? true : false
  end

  # 计算资产占比
  def proportion( input_value = false )
    if positive?
      return amount_to(:twd)/Property.value(:twd, \
        only_positive: true, include_hidden: input_value) *100
    elsif negative?
      return amount_to(:twd)/Property.value(:twd, \
        only_negative: true, include_hidden: input_value) *100
    end
  end

  # 更新资产金额
  def update_amount( new_amount )
    self.amount = new_amount
    save
  end

end

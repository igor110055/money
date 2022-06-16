module ApplicationHelper

  include ActsAsTaggableOn::TagsHelper

  # 为哪些模型自动建立返回列表的链接以及执行返回列表的指令 eq. link_back_to_xxx, go_xxx
  $models = %w(property currency interest item portfolio record deal_record open_order trial_list trade_param trade_strategy digital_currency digital_param)
  # 为哪些类型的通知自动产生方法
  $flashs = %w(notice warning)
  # 建立从列表中快速更新某个值的方法
  $quick_update_attrs = ["property:amount","item:price,amount","currency:exchange_rate"]
  # 资产组合的模式属性
  $modes = %w(none matchall any)
  # 记录数值的模型名称
  $record_classes = \
    %w(property currency interest item portfolio).\
    map{|w| w.capitalize} + ['NetValue','NetValueAdmin']

  # 建立返回列表的链接
  $models.each do |n|
    define_method "link_back_to_#{n.pluralize}" do
      eval("raw(\"" + '#{' + "link_to t(:#{n}_index), #{n.pluralize}_path" + "}\")")
    end
  end

  # 交易参数的类型选项
  def trade_param_type_arr
    [ ['boolean','b'],['datetime','dt'],['decimal','d'],['integer','i'],['string','s']]
  end

  # 交易策略的交易类型
  def trade_deal_type_arr
    [ ['限价买','bl'],['市价买','bm'],['限价卖','sl'],['市价卖','sm'] ]
  end

  # 网站标题
  def site_name
    $site_name
  end

  # 网站Logo图示
  def site_logo
    raw image_tag($site_logo, width: $site_logo_width, height: $site_logo_height, id: "site_logo", alt: site_name, align: "absmiddle")
  end

  # 判断是否已登入
  def login?
    session[:login] == true
  end

  # 判断是否已登入
  def admin?
    if session and session[:admin]
      return session[:admin] == true
    else
      return false
    end
  end

  # 默认的数字显示格式
  def to_n( number, pos=2, opt={} )
    if number and number.class == String
      if number.strip!
        number.sub!("<_io.TextIOWrapper name='<stdout>' mode='w' encoding='UTF-8'>",'')
      end
    end
    if number.class != Array and number = number.to_f
      if opt[:round]
        return format("%.#{pos}f",number)
      else
        return number > 0 ? format("%.#{pos}f",number.floor(pos)) : format("%.#{pos}f",number.ceil(pos))
      end
    else
      return format("%.#{pos}f",0)
    end
  end

  # 默认的金额显示格式
  def to_amount( number, is_digital = false )
    if is_digital
      return format("%.8f",number)
    else
      return to_n( number, 2 )
    end
  end

  # 默认的时间显示格式
  def to_t( time, simple = false )
    if !simple
      time.to_s(:db)
    else
      time.strftime("%Y%m%d-%H%M%S")
    end
  end

  # 默认的日期显示格式
  def to_d( date, simple = false, six_num = false )
    if simple
      date.strftime("%y-%m-%d")
    elsif six_num
      date.strftime("%y%m%d")
    else
      date.to_s(:db)
    end
  end

  # 默认的时间显示格式
  def to_time( time )
    time.strftime("%Y-%m-%d %H:%M:%S")
  end

  # 点击后立刻选取所有文字
  def select_all
    'this.select()'
  end

  # 移动鼠标能改变表格列的背景颜色
  def change_row_color( over_rgb='#FFCF00', out_rgb='#FFFFFF' )
    raw "onMouseOver=\"this.style.background='#{over_rgb}'\"  onMouseOut=\"this.style.background='#{out_rgb}'\" style=\"background-color:#{out_rgb}\""
  end

  # 链接到编辑类别
  def link_edit_to( instance, link_text = instance.name, back_path = nil, options = {} )
    path_str = ", path: '#{back_path}'" if !back_path.nil?
    eval "link_to '#{link_text}', {controller: :#{instance.class.table_name}, action: :edit, id: #{instance.id}#{path_str}}, #{options}"
  end

  # 链接到编辑类别
  def link_edit_to_image( instance, image_name = 'doc.png', back_path = nil )
    path_str = ", path: '#{back_path}'" if !back_path.nil?
    eval "link_to image_tag('#{image_name}'), {controller: :#{instance.class.to_s.downcase.pluralize}, action: :edit, id: #{instance.id}#{path_str}}, {id:'#{instance.class.name.downcase}_edit_#{instance.id}'}"
  end

  # 用户在新建利息或商品时不能看到隐藏资产以供选择
  def select_property_id( obj )
    scope = admin? ? 'all' : 'all_visible'
    eval("obj.select :property_id, Property.#{scope}.collect { |p| [ p.name, p.id ] }")
  end

  # 资产组合新增模式属性以便能支持所有法币资产的查看
  def select_portfolio_mode( obj )
    eval("obj.select :mode, $modes.collect {|m| [m, m[0]]}")
  end

  # 选择交易记录的分类
  def select_record_model( obj )
    eval("obj.select :class_name, $record_classes.collect {|m| [m, m]}")
  end

  # 选择交易记录的账号
  def select_deal_record_account( obj )
    eval("obj.select :account, ['135','170'].collect {|a| [a, a]}")
  end

  # 选择交易记录的账号
  def select_huobi_account( account = '170' )
    select_tag "account", options_for_select([ "135", "170" ], account)
  end

  # 选择交易的类型
  def select_order_type( deal_type )
    select_tag "deal_type", options_for_select([ ["限价买", "buy-limit"], ["市价买", "buy-market"], ["限价卖", "sell-limit"], ["市价卖", "sell-market"] ], deal_type)
  end

  # 选择交易记录的类型
  def select_deal_record_type( obj )
    eval("obj.select :deal_type, ['buy','sell'].collect {|m| [m.upcase, m]}")
  end

  # 更新所有汇率的链接
  def update_all_exchange_rates_link
    link_to t(:update_all_exchange_rates), {controller: :currencies, action: :update_all_exchange_rates, path: request.fullpath}, {id:'update_all_exchange_rates'}
  end

  # 更新法币汇率的链接
  def update_all_legal_exchange_rates_link
    link_to t(:update_all_legal_exchange_rates), {controller: :currencies, action: :update_all_legal_exchange_rates, path: request.fullpath}, {id:'update_all_legal_exchange_rates'}
  end

  # 更新所有数字货币汇率的链接
  def update_all_digital_exchange_rates_link
    link_to t(:update_all_digital_exchange_rates), {controller: :currencies, action: :update_all_digital_exchange_rates, path: request.fullpath}, {id:'update_all_digital_exchange_rates'}
  end

  # 更新比特币汇率的链接
  def update_btc_exchange_rates_link
    link_to t(:update_btc_exchange_rates), {controller: :currencies, action: :update_btc_exchange_rates, path: request.fullpath}, {id:'update_btc_exchange_rates'}
  end

  # 更新全部的链接
  def update_all_data_link
    link_to t(:update_all_data), {controller: :properties, action: :update_all_data, path: request.fullpath}, {id:'update_all_data'}
  end

  # 更新比特币的链接
  def update_btc_link
    link_to t(:update_btc), {controller: :currencies, action: :update_btc_exchange_rates, path: request.fullpath}, {id:'update_btc_exchange_rates'}
  end

  # 更新火币的链接
  def update_huobi_data_link
    link_to t(:update_huobi_data), {controller: :main, action: :update_huobi_data, path: request.fullpath}, { id: 'update_huobi_data' }
  end

  # 更新火币的链接
  def update_huobi_assets_link
    link_to t(:update_huobi_assets), {controller: :main, action: :update_huobi_assets, path: request.fullpath}, { id: 'update_huobi_assets' }
  end

  # 更新火币的链接
  def update_huobi_records_link
    link_to t(:update_huobi_records), {controller: :main, action: :update_huobi_records, path: request.fullpath}, { id: 'update_huobi_records' }
  end

  # 更新资产组合的链接
  def update_all_portfolios_link
    link_to t(:update_all_portfolios), {controller: :portfolios, action: :update_all_portfolios, path: request.fullpath}, {id:'update_all_portfolios'}
  end

  # 更新房价的链接
  def update_house_price_link
    link_to t(:update_house_price), {controller: :items, action: :update_house_price, path: request.fullpath}, {id:'update_house_price'}
  end

  # 下单列表链接
  def order_list_link
    link_to t(:order_list), {controller: :open_orders}, {id:'open_orders'}
  end

  # 下单列表链接
  def check_open_orders_link
    link_to t(:check_open_orders), {controller: :open_orders, action: :check_open_order}, {id:'check_open_orders'}
  end

  # K线图链接
  def kline_chart_link( text = to_n(get_btc_price), symbol = "btcusdt" )
    pos = text.to_f > 100 ? 0 : 2
    eval("@cny_value_for_#{symbol} = (text.to_f*$usdt_to_cny).floor(pos)")
    eval("@twd_value_for_#{symbol} = (text.to_f*$usdt_to_twd).floor(pos)")
    link_to text, {controller: :main, action: :kline_chart, symbol: symbol}, {target: :blank, title: "#{symbol.upcase}: ¥#{eval("@cny_value_for_#{symbol}")}｜#{eval("@twd_value_for_#{symbol}")}" }
  end

  # K线图链接
  def line_chart_link( currency, opt={} )
    if !currency.symbol_code.empty?
      text = opt[:show] == 'name' ? currency.name : currency.symbol_code
      return raw(link_to text, {controller: :main, action: :line_chart, symbol: currency.symbol_code.downcase}, {target: :blank})
    elsif opt[:name]
      return currency.name
    else
      return ''
    end
  end

  # 显示交易所资产的链接
  def huobi_assets_link
    link_to t(:huobi_assets), properties_path(tags:get_huobi_acc_id)
  end

  # 定投记录链接
  def invest_log_link( code = "BTC", text = "Log" )
    code.upcase!
    if code == "BTC" or code == "SBTC"
      link_to text, invest_log_path
    elsif code == "ETH" or code == "SETH"
      link_to text, invest_eth_log_path
    elsif code == "MANA" or code == "SMANA"
      link_to text, invest_mana_log_path
    end
  end

  # 清空定投记录链接
  def clear_invest_log_link
    link_to t(:clear_invest_log), delete_invest_log_path(path: request.fullpath)
  end

  # 彻底清空定投记录链接
  def total_clear_invest_log_link
    link_to '彻底清空', clear_invest_log_path(path: request.fullpath)
  end

  # 撤消全部下单并清空记录链接
  def clear_open_orders_link
    link_to t(:clear_open_orders), clear_open_orders_path, { id: 'clear_open_orders' }
  end

  # 50:50的数学模型测试
  def model_trade_single_link
    link_to t(:model_trade_single), mtrade_log_path
  end

  # 50:50的数学模型测试
  def model_trade_link
    link_to t(:model_trade_set), mtrades_log_path
  end

  # 储存报价数据
  def save_kdata_link
    link_to t(:save_kdata), save_kdata_path
  end

  # 设置定投参数表单链接
  def set_auto_invest_form_link( code = "BTC", link_text = "参数设定", opt = {} )
    if code == "BTC"
      link_to link_text, set_auto_invest_form_path(opt), { id: 'set_auto_invest_form' }
    elsif code == "SBTC"
      link_to link_text, set_auto_sell_btc_form_path(opt), { id: 'set_auto_sell_btc_form' }
    elsif code == "SETH"
      link_to link_text, set_auto_sell_eth_form_path(opt), { id: 'set_auto_sell_eth_form' }
    elsif code == "MANA"
      link_to link_text, set_auto_buy_mana_form_path(opt), { id: 'set_auto_buy_mana_form' }
    end
  end

  # 更新系统参数表单链接
  def system_params_form_link
    link_to t(:update_system_params), system_params_form_path, { id: 'system_params_form' }
  end

  # 火币测试链接
  def test_huobi_link
    link_to t(:test_huobi), '/test_huobi.json', { id: 'test_huobi' }
  end

  # 与资产更新相关的链接
  def update_btc_huobi_portfolios_link
    raw( update_huobi_assets_link + \
    ' | ' + update_btc_exchange_rates_link + ' | ' + update_all_portfolios_link + ' | ')
  end

  # 清空未卖出的交易记录
  def clear_deal_records_link
    link_to t(:clear_deal_records), clear_deal_records_path
  end

  # 卖到回本
  def sell_to_back_link
    sell_max_cny = get_invest_params(23).to_i
    btc_and_usdt_to_cny = DealRecord.btc_and_usdt_to_cny.to_i
    net_profit_cny = btc_and_usdt_to_cny - sell_max_cny
    if DealRecord.unsell_count > 0 and net_profit_cny > 0
      link_to t(:sell_to_back)+"¥#{sell_max_cny}(+#{net_profit_cny})", sell_to_back_path
    else
      t(:operate_money)+"(#{btc_and_usdt_to_cny})"
    end
  end

  # 仓位试算表链接
  def level_trial_list_link
    link_to t(:level_trial_list), controller: :main, action: :level_trial_list
  end

  # 涨跌试算表链接
  def rise_fall_list_link
    link_to t(:rise_fall_list), controller: :main, action: :rise_fall_list
  end

  # 资产标签云
  def get_tag_cloud
    @tags = Property.tag_counts_on(:tags)
  end

  # 建立排序上下箭头链接
  def link_up_and_down( id )
    raw(link_to('↑', action: :order_up, id: id)+' '+\
        link_to('↓', action: :order_down, id: id))
  end

  # 点击图标查看资产组合明细
  def look_portfolio_detail( portfolio )
    raw(link_to(portfolio.name,
      {controller: :properties, action: :index, portfolio_name: portfolio.name,
        tags: portfolio.include_tags, extags: portfolio.exclude_tags, mode: portfolio.mode, pid: portfolio.id},{id:"portfolio_#{portfolio.id}"}))
  end

  # 显示资产组合名称
  def portfolio_name
    text = ''
    if params[:portfolio_name]
      text = params[:portfolio_name]
    elsif params[:tags]
      text = params[:tags]
    end
    raw("<span class=\"sub_title\">(#{text})</span>") if !text.empty?
  end

  def item_url( obj )
    url = obj.url ? obj.url : ''
    if !url.empty? and url.index('http')
      return raw(link_to(t(:item_url),url,{target: :blank}))
    end
    return t(:item_url)
  end

  # 显示数据创建及更新时间
  def timestamps( obj )
    if !obj.new_record?
      raw("<div class='timestamps'>
        #{t(:created_at)}: #{obj.created_at.to_s(:db)}
        #{t(:updated_at)}: #{obj.updated_at.to_s(:db)}
      </div>")
    end
  end

  # 显示删除某笔数据链接
  def link_to_delete( obj )
    if !obj.new_record?
      name = obj.class.table_name.singularize
      raw(' | '+eval("link_to t(:delete_#{name}), delete_#{name}_path(@#{name}), id: 'delete_#{name}'"))
    end
  end

  # 显示资产统计讯息
  def show_summary_tr( colspan )
   raw "<tr>
          <td colspan='#{colspan}' class='thead'>
            #{render 'shared/summary'}
          </td>
        </tr>"
  end

  # 重新读取资产净值
  def reload_net_value( admin = admin? )
    @properties_net_value_twd = Property.net_value :twd, admin_hash(admin)
    @properties_net_value_cny = Property.net_value :cny, admin_hash(admin)
  end

  def show_trial_cost_month_from_tag
    $trial_cost_month_from_tag == '' ? '流动性资产' : $trial_cost_month_from_tag
  end

  def properties_tags_link
    if $trial_cost_month_from_tag == ''
      properties_path(extags:'贷款 房产',mode:'a',pid:13,portfolio_name:'流动性资产总值',tags:$total_flow_assets_tags)
    else
      properties_path(tags:$trial_cost_month_from_tag)
    end
  end

  # 修正若分类名称遇到空白则显示默认的流动性资产总值
  def trial_cost_month_name
   $trial_cost_month_from_tag.empty? ? '流动性资产' : $trial_cost_month_from_tag
  end

  # 回传比特币总数
  def sum_of_btc
    Property.tagged_with('比特币').sum {|p| p.amount}
  end

  # 回传以太坊总数
  def sum_of_eth
    Property.tagged_with('以太坊').sum {|p| p.amount}
  end

  # 回传CRYPTO总数
  def sum_of_crypto(crypto_code)
    Property.tagged_with(crypto_code.upcase).sum {|p| p.amount}
  end

  # 回传泰达币总数
  def sum_of_usdt
    Property.tagged_with('泰达币').sum {|p| p.amount}
  end

  # 比特币持有数相当于多少人民币
  def btc_eq_cny
    @p_btc ||= sum_of_btc
   (@p_btc*get_btc_price*$usdt_to_cny).to_i
  end

  # 以太坊持有数相当于多少人民币
  def eth_eq_cny( eth_price = 0 )
    @p_eth ||= sum_of_eth
    if eth_price > 0
      return (@p_eth*eth_price*$usdt_to_cny).to_i
    else
      return (@p_eth*get_eth_price*$usdt_to_cny).to_i
    end
  end

  # CRYPTO持有数相当于多少人民币
  def crypto_eq_cny( crypto_code, crypto_price = 0 )
    amount = sum_of_crypto(crypto_code)
    if crypto_price > 0
      return (amount*crypto_price*$usdt_to_cny).to_i
    else
      return (amount*get_crypto_price(crypto_code)*$usdt_to_cny).to_i
    end
  end

  # 泰达币持有数相当于多少人民币
  def usdt_eq_cny
   (sum_of_usdt*$usdt_to_cny).to_i
  end

  # 比特币持有数相当于多少台币
  def btc_eq_twd
    @cny2twd ||= Property.new.cny_to_twd
   (btc_eq_cny*@cny2twd).to_i
  end

  # 以太坊持有数相当于多少台币
  def eth_eq_twd
    @cny2twd ||= Property.new.cny_to_twd
   (eth_eq_cny*@cny2twd).to_i
  end

  # 显示资产净值链接
  def show_net_value_link
    reload_net_value
    twd2cny = Property.new.twd_to_cny
    cny2twd = Property.new.cny_to_twd
    cny2btc = Property.new.cny_to_btc
    cny2usdt = Property.new.cny_to_usdt
    total_flow_assets_twd = Property.total_flow_assets_twd.to_i # 总的流动性资产总值
    total_flow_assets_cny = (total_flow_assets_twd*twd2cny).to_i
    flow_assets_twd = Property.flow_assets_twd.to_i # 流动性资产总值(135/170)
    tag_value_twd = Property.tag_value_twd($trial_cost_month_from_tag).to_i # 冷钱包目前的值
    btc_value_twd = Property.btc_value_twd.to_i # 比特币资产总值
    investable_fund_twd = Property.total_investable_fund_records_twd.to_i # 可买币资产总值
    total_loan_lixi_twd = Property.total_loan_lixi.to_i # 总的所有贷款含利息
    loan_lixi_twd = Property.loan_lixi.to_i # 所有贷款含利息(135/170)
    month_cost_max = $trial_life_month_cost_cny_admin # 每个月生活费
    keep_years = $keep_life_years # 至少保留几年的生活费
    tag_value_twd = total_flow_assets_twd if $trial_cost_month_from_tag == '' # 空白表示显示流动性资产总值
    if admin?
      flow_subtract_loan_twd = total_flow_assets_twd - total_loan_lixi_twd # 总的流动性扣除贷款
      remain_months = (tag_value_twd*twd2cny/month_cost_max).to_i
    else
      flow_subtract_loan_twd = flow_assets_twd - loan_lixi_twd # 流动性扣除贷款(135/170)
      remain_months = (flow_assets_twd*twd2cny/month_cost_max).to_i
    end
    # 扣除保留的生活费，可用于投资的资金
    remain_money = tag_value_twd*twd2cny-(keep_years*12+1)*month_cost_max
    remain_bitcoin = remain_money*cny2btc
    @remain_money_to_invest = remain_money
    # 依照统计币别显示每月生活费
    month_cost_max_twd = (month_cost_max*cny2twd).to_i
    show_month_cost_max = $show_value_cur == 'CNY' ? "¥#{month_cost_max}" : month_cost_max_twd
    # 计算能维持生活费到设定的年数所需要的币价 (总费用-以太坊总值-泰达币总值-保单可借余额)/比特币个数/汇率
    @p_btc ||= sum_of_btc
    begin
      # @btc_price_goal_of_keep_years = ((month_cost_max*keep_years*12-eth_eq_cny-usdt_eq_cny-($loan_max_twd*twd2cny))/@p_btc*cny2usdt).to_i
      # x = (a-ex-b-c)*d
      ethbtc_ex_rate = get_ethbtc_price.floor(6)
      a = month_cost_max*keep_years*12
      b = usdt_eq_cny
      c = $loan_max_twd*twd2cny + $loan_max_cny
      d = cny2usdt/@p_btc
      e = sum_of_eth*ethbtc_ex_rate*$usdt_to_cny
      @btc_price_goal_of_keep_years = ((a-b-c)*d/(1+e*d)).to_i
      @eth_price_goal_of_keep_years = (@btc_price_goal_of_keep_years*ethbtc_ex_rate).to_i
    rescue
      @btc_price_goal_of_keep_years = @eth_price_goal_of_keep_years = 0
    end
    @month_cost_str = "维持#{keep_years}年生活(#{show_month_cost_max}/月): #{@btc_price_goal_of_keep_years}(BTC) #{@eth_price_goal_of_keep_years}(ETH)"
    @remain_invest_str = "扣除#{keep_years}年#{@month_cost_str}后的投资额:¥#{remain_money.to_i}(฿#{remain_bitcoin.floor(4)})"
    flow_subtract_loan_cny = (flow_subtract_loan_twd*twd2cny).to_i
    net_growth_ave_month_twd = to_n(@properties_net_growth_ave_month/10000.0,1)
    net_growth_ave_month_cny = to_n(@properties_net_growth_ave_month_cny/10000.0,1)
    # 依照统计币别显示资产净值平均每月增加多少
    show_net_growth_month = $show_value_cur == 'CNY' ? net_growth_ave_month_cny : net_growth_ave_month_twd
    if admin?
      main_info = "<span id=\"properties_net_value_twd\" title=\"总资产扣除贷款：#{@properties_net_value_twd.to_i}\n#{t(:cny)}资产净值：#{@properties_net_value_cny.to_i}\n流动性资产总值：#{flow_assets_twd}\n比特币资产总值：#{btc_value_twd}\n所有贷款含利息：#{total_loan_lixi_twd}\n流动性扣除贷款：#{flow_subtract_loan_twd}\">\
      #{link_to(@properties_net_value_twd.to_i/10000, records_path(num:2,chart:1), target: :blank)}(¥#{@properties_net_value_cny.to_i/10000})</span>"
      addon_info = " |<span id=\"properties_net_value_cny\" title=\"流动性资产总值(不含贷款)：#{total_flow_assets_twd}(¥#{total_flow_assets_cny})\">\
      #{link_to(total_flow_assets_twd/10000,'/properties?extags=&mode=a&pid=13&portfolio_name=流动性资产总值&tags='+$total_flow_assets_tags)}(¥#{total_flow_assets_cny/10000})</span> | <span title=\"流动性资产扣除贷款的净值：#{flow_subtract_loan_twd}(¥#{flow_subtract_loan_cny})|#{t(:begin_profit_price)}:#{Property.begin_profit_price.to_i}\">\
      #{flow_subtract_loan_twd}(¥#{flow_subtract_loan_cny})</span> ｜ <span id=\"net_growth_ave_month\" title=\"#{$net_start_date}起资产净值每月增加¥#{@properties_net_growth_ave_month_cny}(#{@properties_net_growth_ave_month})\">#{show_net_growth_month}</span>"
      flow_assets_info = "#{(tag_value_twd*twd2cny).to_i}|#{tag_value_twd}"
    else
      main_info = "<span id=\"flow_subtract_loan_twd\" title=\"减去贷款后的流动性资产总值\">¥#{link_to((flow_subtract_loan_twd*twd2cny).to_i, records_path(num:2,chart:1), target: :blank)}</span>"
      addon_info = ''
      flow_assets_info = "#{(flow_assets_twd*twd2cny).to_i}|#{flow_assets_twd}"
    end
    # 可贷款余额 = 新光保单ATM可借余额 + 太平保单可借余额
    loan_max_twd = $loan_max_twd + $loan_max_cny*cny2twd
    # 计算以现有资金均摊到每个月的生活费
    ave_month_useable = (tag_value_twd*twd2cny/(keep_years*12)).to_i
    # 计算以现有资金均摊到每个月的生活费 + 可贷款余额
    ave_month_useable_plus = ((tag_value_twd+loan_max_twd)*twd2cny/(keep_years*12)).to_i
    # 计算以现有资金除以每个月生活费能撑几年
    years_useable = to_n(remain_months/12.0,1)
    # 计算以(现有资金+保单可借余额)除以每个月生活费能撑几个月
    months_useable_plus = (((tag_value_twd+loan_max_twd)*twd2cny)/month_cost_max).to_i
    ave_month_useable_twd = (ave_month_useable*cny2twd).to_i
    ave_month_useable_plus_twd = (ave_month_useable_plus*cny2twd).to_i
    # 依照统计币别显示 ave_month_useable 和 ave_month_useable_plus
    show_ave_month_useable = $show_value_cur == 'CNY' ? "¥#{ave_month_useable}" : ave_month_useable_twd
    show_ave_month_useable_plus = $show_value_cur == 'CNY' ? "¥#{ave_month_useable_plus}" : ave_month_useable_plus_twd
    month_growth_rate =
    raw "#{main_info}#{addon_info}|<span title=\"#{trial_cost_month_name}总值(¥#{flow_assets_info})可用于生活#{remain_months}个月或#{years_useable}年(每月¥#{month_cost_max}|#{(month_cost_max/twd2cny).to_i})加上贷款最多可生活#{months_useable_plus}个月或#{to_n(months_useable_plus/12.0,1)}年。#{@remain_invest_str}\">#{link_to(years_useable,properties_tags_link)}:(#{remain_months}|#{months_useable_plus})</span>|#{keep_years}:(<span title=\"#{trial_cost_month_name}均摊到#{keep_years}年的每月生活费(¥#{ave_month_useable}|#{ave_month_useable_twd})\">#{show_ave_month_useable}</span>|<span title=\"#{trial_cost_month_name}加新光保单ATM可借余额均摊到#{keep_years}年的每月生活费(¥#{ave_month_useable_plus}|#{ave_month_useable_plus_twd})\">#{show_ave_month_useable_plus}</span>)"
  end

  # Fusioncharts属性大全: http://wenku.baidu.com/link?url=JUwX7IJwCbYMnaagerDtahulirJSr5ASDToWeehAqjQPfmRqFmm8wb5qeaS6BsS7w2_hb6rCPmeig2DBl8wzwb2cD1O0TCMfCpwalnoEDWa
  def show_fusion_chart
    raw "<div id=\"chartContainer\"></div><p>
    <script type=\"text/javascript\">
    FusionCharts.ready(function () {
        var myChart = new FusionCharts({
          \"type\": \"line\",
          \"renderAt\": \"chartContainer\",
          \"width\": \"100%\",
          \"height\": \"450\",
          \"dataFormat\": \"xml\",
          \"dataSource\": \"<chart yAxisMinValue='#{@bottom_value}' yAxisMaxvalue='#{@top_value}' animation='0' caption='#{@caption}' xaxisname='　' yaxisname='' formatNumberScale='0' formatNumber ='0' palettecolors='#CC0000' bgColor='#F0E68C' canvasBgColor='#F0E68C' valuefontcolor='#000000' showValues='0' borderalpha='0' canvasborderalpha='0' theme='fint' useplotgradientcolor='0' plotborderalpha='0' placevaluesinside='0' rotatevalues='1'  captionpadding='5' showaxislines='0' axislinealpha='0' divlinealpha='0' lineThickness='3' drawAnchors='1'>#{@chart_data}</chart>\"
        });
      myChart.render();
    });
    </script>"
  end

  # 建立查看走势图链接
  def chart_link( obj )
    raw(link_to(image_tag('chart.png',width:16),{controller: obj.class.name.pluralize.downcase.to_sym, action: :chart, id: obj.id},{target: :blank}))
  end

  # 显示火币时间讯息使用
  def get_timestamp
    timestamp = `python py/timestamp.py`
    puts "timestamp = #{timestamp}"
    return timestamp.to_i
  end

  # 将UTC time in millisecond显示成一般日期格式
  def show_time( utc_time )
    if timestamp = get_timestamp and timestamp > 0
      (Time.now-(get_timestamp-utc_time.to_i/1000).second).strftime("%Y-%m-%d %H:%M:%S")
    end
  end

  # 是否显示打勾的图示
  def show_ok( boolean, title = '', width = 15 )
    image_tag('ok.png',width:width,title:title) if boolean
  end

  # 显示交易类别
  def show_deal_type( type )
    type.index('buy') ? '买进' : '卖出'
  end

  # 显示交易类别
  def get_deal_type( type )
    if rs = trade_deal_type_arr.rassoc(type)
      return rs[0]
    else
      return ""
    end
  end

  # 显示较长的文字数据
  def show_long_text( string, length = 10 )
    raw "<span title='#{string}'>#{truncate(string,length: length)}</span>"
  end

  # 显示附加文字的内容
  def add_title( text, title )
    raw "<span title='#{title}'>#{text}</span>"
  end

  # 显示投资目的字符串
  def show_purpose( purpose )
    ": #{purpose}" if purpose and !purpose.empty?
  end

  # 显示绿色或红色背景
  def if_red_bg( value, compare )
    raw('class="red_bg"') if compare.to_f > 0 and value.to_f > compare.to_f
  end

  # 显示绿色或红色背景
  def if_green_bg( value, compare )
    raw('class="green_bg"') if compare.to_f > 0 and value.to_f < compare.to_f
  end

  # 显示火币下单链接(显示价格,个别数据具柄,earn_or_loss)
  def huobi_order_link( price, dr, el, link = true )
    if link
    link_to(add_title(price,"¥#{eval("dr.#{el}_limit")}#{show_purpose(dr.purpose)}"), controller: :main, action: :place_order_form, id: dr.id, type: el) if price.to_f > 0
    else
      add_title(price,"¥#{eval("dr.#{el}_limit")}#{show_purpose(dr.purpose)}")
    end
  end

  # 火币下单链接
  def order_link( amount = nil, text = t(:huobi_order) )
    link_to text, controller: :main, action: :place_order_form, amount: amount
  end

  # 建立查看火币下单链接
  def look_order_link( dr, text )
    if dr.order_id and !dr.order_id.empty?
      link_to(text, {controller: :main, action: :look_order, account: dr.account, id: dr.order_id},{target: :blank})
    else
      text
    end
  end

  def symbol_title(symbol)
    s = symbol.upcase.sub("USDT","/USDT").sub("HUSD","/HUSD")
    s = s[1..-1] if s[0] == "/"
    return s
  end

  def period_title(period)
    period.sub("min","分钟").sub("hour","小时").sub("day","天").sub("week","周").sub("mon","月").sub("year","年")
  end

  # 修正divided by 0错误
  def fix_zero_price( price )
  	return 10 if price == 0
  end

  # 取得最新的比特币报价
  def btc_price
    begin
      if $auto_update_btc_price > 0
        root = JSON.parse(`python py/huobi_price.py symbol=btcusdt period=1min size=1 from=0 to=0`)
        if root["data"] and root["data"][0]
          return format("%.2f",root["data"][0]["close"]).to_f
        else
          return btc_price_local
        end
      else
        return btc_price_local
      end
    rescue
      return btc_price_local
    end
  end

  def btc_price_local
    Currency.find_by_code('BTC').to_usd.floor(2)
  end

  # 显示切换分钟链接
  def period_link_for_chart(action)
    result = ""
    result += "<span class='sub_text'>#{link_to t(:deal_record_index), controller: :deal_records}</span>"
    %w[1min 5min 15min 30min 60min 4hour 1day 1week 1mon].each do |period|
    result += "<span class='sub_text'>#{link_to period_title(period), action: action, symbol: params[:symbol], period: period}</span>"
    end
    swap_action = action == :kline_chart ? :line_chart : :kline_chart
    swap_label = swap_action == :kline_chart ? t(:see_kline) : t(:see_line)
    result += "<span class='sub_text'>#{link_to swap_label, action: swap_action, symbol: params[:symbol], period: params[:period]}</span>"
    return raw(result)
  end

  # 获取未卖出的交易笔数
  def get_unsell_deal_records_count
    DealRecord.unsell_count
  end

  # 根据code回传文档路径
  def get_invest_params_path( code = "BTC" )
    if code == "BTC"
      return $auto_buy_btc_params_path
    elsif code == "SBTC"
      return $auto_sell_btc_params_path
    elsif code == "ETH" or code == "SETH"
      return $auto_sell_eth_params_path
    elsif code == "MANA"
      return $auto_buy_mana_params_path
    end
  end

  # 获取定投参数的值
  def get_invest_params( index, code = "BTC" )
    code.upcase!
    begin
      if code == "BTC"
        return File.read(get_invest_params_path("BTC")).split(' ')[index]
      elsif code == "SBTC"
        return File.read(get_invest_params_path("SBTC")).split(' ')[index]
      elsif code == "ETH" or code == "SETH"
        return File.read(get_invest_params_path("ETH")).split(' ')[index]
      elsif code == "MANA"
        return File.read(get_invest_params_path("MANA")).split(' ')[index]
      end
    rescue
      return '0'
    end
  end

  # 储存定投参数的值
  def set_invest_params( code, index, value )
    begin
      params_values = File.read(get_invest_params_path(code)).split(' ')
      params_values[index.to_i] = value.to_s
      write_invest_params params_values.join(' '), code
      return true
    rescue
      return false
    end
  end

  # 写入定投参数
  def write_to_file( file_path, text )
    begin
      File.open(file_path, 'w+') do |f|
        f.write(text)
      end
      return true
    rescue
      return false
    end
  end

  # 写入定投参数
  def write_invest_params( text, code = "BTC" )
    write_to_file( get_invest_params_path(code), text )
  end

  # 读取火币APP的账号ID
  def get_huobi_acc_id
    if $huobi_acc_id
      return $huobi_acc_id
    else
      if __FILE__.index("/money/")
        $huobi_acc_id = '135'
      elsif __FILE__.index("/money2/")
        $huobi_acc_id = '170'
      end
    end
  end

  # 显示定投参数的设定值链接(数字版)
  def invest_params_setup_link( code, index, min, max, step = 1, pos = 0, add_zero_value = false, step_arr = nil )
    result = ''
    arr = step_arr ? step_arr : (min..max).step(step)
    arr.each do |n|
      value = to_n(n.floor(pos),pos)
      style = (!@already_show and value == get_invest_params(index,code)) ? 'invest_param_select' : ''
      result += link_to(value, setup_invest_param_path(i:index,v:value,c:code), class: style) + ' '
    end
    if add_zero_value
      value = '0'
      style = (!@already_show and value == get_invest_params(index,code)) ? 'invest_param_select' : ''
      result = link_to(value, setup_invest_param_path(i:index,v:value,c:code), class: style) + ' ' + raw(result)
    end
    @already_show = false
    return raw(result)
  end

  # 显示定投参数的设定值链接(文字版)
  def invest_text_setup_link( code, index, text )
    result = ''
    text.split(' ').each do |value|
      style = (!@already_show and value == get_invest_params(index,code)) ? 'invest_param_select' : ''
      result += link_to(value, setup_invest_param_path(i:index,v:value,c:code), class: style) + ' '
    end
    @already_show = false
    return raw(result)
  end

  # 登出系统的链接
  def logout_link
    link_to t(:logout), logout_path, { id: 'logout' }
  end

  # 用于收支试算函数
  def cal_btc_capital
    if @btc_total_amount > 0
      @btc_capital = (@btc_price*@btc_total_amount*$usdt_to_cny).to_i
    else
      @btc_capital = 0
    end
  end

  # 用于收支试算函数
  def btc_capital_twd
    (@btc_capital*@cny2twd).to_i
  end

  # 检查最新的比特币报价是否已达成数据库储存的理财目标
  def check_trial_reached( trial_date )
    today = Date.today
    if rs = TrialList.find_by_trial_date(trial_date)
      goal_price = rs.end_price
      goal_balance = rs.end_balance_twd
      month_invest = rs.month_invest.nil? ? 0 : rs.month_invest
      # 計算理財目標的达标价
      reach_goal_price = (rs.end_balance - @investable_fund_records_cny)/(@btc_amount_now*$usdt_to_cny)
      return goal_price, @begin_price_for_trial - goal_price, goal_balance, @flow_assets_twd - goal_balance, reach_goal_price, month_invest
    else
      return 0, 0, 0, 0, 0, 0
    end
  end

  # 理财目标显示的笔数
  def trial_records_number( show_all = false )
    (params[:show_all] == '1' or show_all) ? $trial_save_months : $trial_total_months
  end

  # 显示无定投参数选项的精确值
  def show_invest_param_value( index, code = "BTC" )
    value = get_invest_params(index,code)
    @already_show = true
    raw "<span class=\"invest_param_select\">#{value}</span>"
  end

  # 从标签设定值取出相应的资产数据集
  def get_properties_from_tags( include_tags, exclude_tags = nil, mode = 'n' )
    case mode
      when 'n' # none
        options = {}
      when 'm' # match_all
        options = {match_all: true}
      when 'a' # any
        options = {any: true}
    end
    # 依照包含标签选取
    if include_tags and !include_tags.empty?
      result = Property.tagged_with(include_tags.strip.split(' '),options)
      if exclude_tags and !exclude_tags.empty?
        # 依照排除标签排除
        result = result.tagged_with(exclude_tags.strip.split(' '),exclude: true)
      end
      return result.sort_by{|p| p.amount_to}.reverse
    end
    return nil
  end

  # 显示最近几个小时的获利标题
  def show_num_h_profit( scale = :hour )
    diff_sec = (Time.now - $send_to_trezor_time).to_i
    if scale == :hour
      return raw("<span title='#{diff_sec/(60*60*24)}天'>#{diff_sec/(60*60)}小时</span>")
    else
      return raw("<span title='#{diff_sec/(60*60)}小时'>#{diff_sec/(60*60*24)}天</span>")
    end
  end

  # 根据135/170读取实际冷钱包里的比特币数量
  def trezor_acc_btc_amount
    Property.find($btc_amount_property_id).amount
  end

  # 由系统参数获取要计算的比特币数量
  def get_btc_amounts
    begin
      amount = trezor_acc_btc_amount
      if $trial_btc_amount_admin > 0 # 如果指定了数值就用指定的
        return [$trial_btc_amount_admin,amount]
      else  # 如果没有指定就回传实际值
        return [amount,amount]
      end
    rescue
      return 0
    end
  end

  # 比特币总数量
  def get_total_btc_amounts
    Property.tagged_with('比特币').sum {|p| p.amount}
  end

  # 比特币+以太坊总数量=多少比特币
  def get_btc_eth_amounts
    b = Property.tagged_with('比特币').sum {|p| p.amount}
    e = Property.tagged_with('以太坊').sum {|p| p.amount_to(:btc)}
    return b+e
  end

  # 理财目标的月末目标能连接到流动性资产总值一览表
  def link_to_flow_assets_list( currency = :TWD, twd_to_cny = 0, twd_to_btc = 0 )
    if currency == :TWD
      text = @flow_assets_twd.to_i
    elsif currency == :CNY
      text = (@flow_assets_twd*twd_to_cny).to_i
    end
    text2 = @flow_assets_btc.floor(8)
    link_to text, {controller: :properties, tags: $link_to_flow_assets_list_tags, mode: $link_to_flow_assets_list_mode}, {title: (@flow_assets_twd.to_i).to_s+"(฿#{text2})"}
  end

  # 链接到SBTC交易列表
  def link_to_btc_deal_records
    link_to t(:deal_record_index_btc), deal_records_btc_path
  end

  # 链接到ETH交易列表
  def link_to_eth_deal_records
    link_to t(:deal_record_index_eth), deal_records_eth_path
  end

  # 显示资产时是否包含显示隐藏资产
  def admin_hash( admin, new_options = {} )
    options = admin ? {include_hidden: true} : {include_hidden: false}
    return options.merge new_options
  end

  # 如果没有负号，在前面显示+号
  def add_plus(s_or_i)
    str = s_or_i.to_s
    if !str.index("-")
      return "+"+str
    else
      return str
    end
  end

  # 在数字前面补0显示
  def add_zero( num, pos = 3 )
    if num.to_i > 0
      result = num.to_s
      case pos
        when 5
          if num.to_i < 10000 and num.to_i >=1000
            result = "0"+result
          elsif num.to_i < 1000 and num.to_i >=100
            result = "00"+result
          elsif num.to_i < 100 and num.to_i >=10
            result = "000"+result
          elsif num.to_i < 10
            result = "0000"+result
          end
        when 4
          if num.to_i < 1000 and num.to_i >=100
            result = "0"+result
          elsif num.to_i < 100 and num.to_i >=10
            result = "00"+result
          elsif num.to_i < 10
            result = "000"+result
          end
        when 3
          if num.to_i < 100 and num.to_i >=10
            result = "0"+result
          elsif num.to_i < 10
            result = "00"+result
          end
        when 2
          if num.to_i < 100 and num.to_i >=10
          elsif num.to_i < 10
            result = "0"+result
          end
      end
      return result
    else
      return "0"*pos
    end
  end

  # 将价格取整数
  def get_int_price( price, pos = 100 )
    ((price/pos).to_i+1)*pos
  end

  # 从火币网取得某一数字货币的最新报价
  def get_huobi_price( symbol, fmt = "%.4f" )
    begin
      root = JSON.parse(`python py/huobi_price.py symbol=#{symbol} period=1min size=1 from=0 to=0`)
      if root["data"] and root["data"][0]
        return format(fmt,root["data"][0]["close"]).to_f
      else
        return 0
      end
    rescue
      return 0
    end
  end

  # 快速读取数字货币报价
  def get_digital_price( code )
    if rate = eval("$#{code}_exchange_rate")
      return 1.0/rate
    elsif item = Currency.find_by_code(code)
      return 1.0/item.exchange_rate
    elsif item = Currency.find_by_symbol(code)
      return 1.0/item.exchange_rate
    elsif $auto_update_btc_price == 1 and price = get_huobi_price(code)
      return price
    else
      return 0
    end
  end

  # 取得CRYPTO现价
  def get_crypto_price( crypto_code )
    get_digital_price crypto_code
  end

  # 取得比特币现价
  def get_btc_price
    get_digital_price 'BTC'
  end

  # 取得以太坊现价
  def get_eth_price
    get_digital_price 'ETH'
  end

  # 取得MANA币现价
  def get_mana_price
    get_digital_price 'MANA'
  end

  # 取得狗狗币现价
  def get_doge_price
    get_digital_price 'DOGE'
  end

  # 取得以太坊兑比特币的现价
  def get_ethbtc_price
    return get_eth_price/get_btc_price
  end

  # USDT >> TWD
  def usdt_to_twd
    DealRecord.new.usdt_to_twd
  end

  # 设定模型总测的页面内容
  def set_mt_page_content( text, link_path, message )
    link_str = helpers.link_to(raw(text+" <small>(点此重新执行测试)</small>"),link_path)
    @text = "<div id='mt_title'>#{link_str}</div>\n#{message}"
  end

  # 计算保持仓位所需卖出的币数
  def sell_amount_to_keep_level( a, b, k, p ) # a:原有资金 b:原有币数 k:基准仓位 p:现价
    (((1-k)*p*b-k*a)/p)
  end

  # 计算保持仓位所需买入的币数
  def buy_amount_to_keep_level( a, b, k, p, f ) # a:原有资金 b:原有币数 k:基准仓位 p:现价 f:手续费率
    (k*(p*b+a)-p*b)/(p*(1-f*(1-k)))
  end

  # 计算两时间间隔天数
  def day_diff( from_time, to_time = 0, include_seconds = false )
      from_time = from_time.to_time if from_time.respond_to?(:to_time)
      to_time = to_time.to_time if to_time.respond_to?(:to_time)
      begin
        return (((to_time - from_time).abs)/86400).round
      rescue
        return 0
      end
  end

  # 资产净值变化值
  def show_net_value_change_text
    net_value_change, net_value_change_rate = Record.net_value_change_from($send_to_trezor_time) # 资产净值变化值, 资产净值变化率
    net_value_change_cny = (net_value_change*Currency.new.twd_to_cny).to_i
    net_value_change_twd_day = (net_value_change/$recent_days).to_i
    net_value_change_cny_day = (net_value_change_cny/$recent_days).to_i
    raw "#{show_num_h_profit(:day)}资产变化: #{add_plus(net_value_change_rate)}%(¥#{net_value_change_cny}|#{net_value_change}) ¥#{net_value_change_cny_day}|#{net_value_change_twd_day}/天 ¥#{net_value_change_cny_day*30}|#{net_value_change_twd_day*30}/月"
  end

  def eth2bi
    get_invest_params(1,'ETH')
  end

  # 根据智投参数决定读取哪种报价
  def eth_symbol
     "eth#{eth2bi}"
  end

  # 让title属性换行
  def show_br( text = nil )
    if text
      return raw('&#10;') if !text.empty?
    else
      return raw('&#10;')
    end
  end

  # 设定一次性首页
  def set_as_home_url( url )
    session[:home_url] = url
  end

  # 计算矿机总成本
  def total_mine_cost
    ($mine_ori_cost+$mine_other_cost-$mine_money_back).to_i
  end

  # 切换自动报价的文字显示
  def get_auto_update_btc_price_text
    if $auto_update_btc_price == 1
      "关闭自动报价"
    elsif $auto_update_btc_price == 0
      "开启自动报价"
    end
  end

  # 切换自动报价的文字显示
  def get_auto_update_huobi_assets_text
    if $auto_update_huobi_assets == 1
      "关闭自动报价与火币资产更新"
    elsif $auto_update_huobi_assets == 0
      "开启自动报价与火币资产更新"
    end
  end

  # 切换每分钟自动更新交易列表的文字显示
  def get_auto_refresh_sec_text
    if $auto_refresh_sec == 60
      "关闭每分钟自动更新交易列表"
    elsif $auto_refresh_sec == 0
      "开启每分钟自动更新交易列表"
    end
  end

  # 切换是否开启多空比的文字显示
  def get_show_buy_sell_rate_text
    if $show_buy_sell_rate == 1
      "关闭多空比显示"
    elsif $show_buy_sell_rate == 0
      "开启多空比显示"
    end
  end

  # 更新排序号
  def exe_update_order_num( class_name, order_field = :order_num, ids = class_name.all.order(order_field) )
    ids.each {|i| class_name.find(i).update_attribute( order_field, ids.index(i)+1 )}
  end

  # 执行向上排序
  def exe_order_up( class_name, object_id, order_field = :order_num )
    @ids = []
    class_name.all.order(order_field).each {|d| @ids << d.id}
    @ori_index = @ids.index(object_id.to_i)
    if @ori_index != 0 then
      @ids[@ori_index] = @ids[@ori_index-1]
      @ids[@ori_index-1] = object_id.to_i
      exe_update_order_num( class_name, order_field, @ids )
    end
  end

  # 执行向下排序
  def exe_order_down( class_name, object_id, order_field = :order_num )
    @ids = []
    class_name.all.order(order_field).each {|d| @ids << d.id}
    @ori_index = @ids.index(object_id.to_i)
    if @ori_index != @ids.size-1 then
      @ids[@ori_index] = @ids[@ori_index+1]
      @ids[@ori_index+1] = object_id.to_i
      exe_update_order_num( class_name, order_field, @ids )
    end
  end

  # 读取交易参数数据集
  def get_trade_params
    TradeParam.all.order(:order_num).collect {|p| [ "#{p.title} #{p.name}", p.name ]}
  end

  # 显示现价与k线图链接
  def show_prices_and_chart_links
    results = []
    $show_dprices.each do |c|
      code = c.split(':')[0]
      pos = c.split(':')[1].to_i
      results << kline_chart_link(get_digital_price(code).floor(pos),"#{code.downcase}")
    end
    return raw(results.join(' | '))
  end

  # 计算单笔买入人民币最小值
  def get_min_buy_cny
    (@price_now*0.0001*$usdt_to_cny/10).ceil * 10
  end

  # 回传可贷款总值
  def total_loan_max_cny
    $loan_max_twd*Property.new.twd_to_cny+$loan_max_cny
  end

  # 回传可贷款总值
  def total_loan_max_twd
    $loan_max_twd+$loan_max_cny*Property.new.cny_to_twd
  end

  # 比特币转人民币
  def btc_to_cny( btc_price )
    Currency.new.btc_to_cny(btc_price)
  end

  # 取得系统参数文档内容
  def get_system_params_content
    File.read($system_params_path)
  end

  # 置换系统参数内容
  def replace_system_params_content( from, to )
    text = get_system_params_content
    text.sub! from, to
    write_to_system_params_file text
  end

  # 设定系统参数切换值
  def switch_system_param( name, value1, value2, is_str = true, msg = nil )
    eval_str1 = is_str ? "$#{name} == '#{value1}'" : "$#{name} == #{value1}"
    eval_str2 = is_str ? "$#{name} == '#{value2}'" : "$#{name} == #{value2}"
    if eval(eval_str1)
      params = is_str ? ["$#{name} = '#{eval("$"+name)}'", "$#{name} = '#{value2}'"] : ["$#{name} = #{eval("$"+name)}", "$#{name} = #{value2}"]
    elsif eval(eval_str2)
      params = is_str ? ["$#{name} = '#{eval("$"+name)}'", "$#{name} = '#{value1}'"] : ["$#{name} = #{eval("$"+name)}", "$#{name} = #{value1}"]
    end
    replace_system_params_content(params[0],params[1])
    put_notice msg if msg
  end

  # 系统参数的更新必须确保每一行以钱号开头以免系统无法运作
  def pass_system_params_check(text)
    regx = /^(\$)(\w)+(\s)+(=){1}(\s)+(.)+/
    text.split("\n").each do |line|
      return false if (line =~ regx) != 0
    end
    return true
  end

  # 写入系统参数文档
  def write_to_system_params_file( text )
    if text and pass_system_params_check(text)
      File.open($system_params_path, 'w+') do |f|
        f.write(text)
      end
      return true
    end
    return false
  end

  # 回传某个月的生活费预算
  def get_month_cost( input_date = Date.today )
    $trial_month_costs.each do |item|
      from_date = item.split('-')[0].to_date
      to_date = item.split('-')[1].to_date
      plan_cost = item.split('-')[2].to_i
      if input_date >= from_date and input_date < to_date
        return plan_cost
      end
    end
    return 0
  end

  # 当期间大于60分钟后改以小时显示
  def show_period( minutes )
    if minutes < 60
      return "#{minutes}分"
    else
      if minutes % 60 == 0
        return "#{minutes/60}小时"
      else
        return "#{(minutes/60.0).floor(1)}小时"
      end
    end
  end

  # 当期间大于60秒后以分钟显示,60分钟后改以小时显示
  def show_period_sec( second )
    if second < 60
      return "#{second}秒"
    else
      return show_period(second/60)
    end
  end

  # 传入货币价格阵列, 计算新的资产总值
  def cal_assets_value_from_input_prices( assets_tags, curr_prices, target_curr = :cny )
    result = 0
    Property.new.get_properties_from_tags(assets_tags,nil,'a').each do |p|
      # value = p.amount*currency_to_target_curr
      symbol = p.currency.symbol
      code = p.currency.code
      # 如果是数字货币且包含在已输入的价格阵列里
      if symbol and !symbol.empty? and curr_prices.include?(symbol.sub('usdt','').to_sym)
        result += p.amount_to(target_curr,curr_prices[:btc],Date.today,{crypto_price: curr_prices[code.downcase.to_sym]})
      # 如果是数字货币但不包含在已输入的价格阵列里
    elsif symbol and !symbol.empty?
        result += p.amount_to(target_curr,curr_prices[:btc],Date.today,{crypto_price: get_digital_price(code)})
      # 如果是一般法币
      else
        result += p.amount_to(target_curr)
      end
    end
    return result.to_i
  end

  # 显示当前的卖出策略
  def show_sell_strategy( code )
    every_second = get_invest_params(22,code).to_i
    sell_over_price = get_invest_params(27,code).to_i
    sell_when_minutes = get_invest_params(18,code).to_i
    min_sell_price = get_invest_params(38,code).to_i
    sell_cny = get_invest_params(39,code).to_i
    # 选择自动定投
    result = "大于#{sell_over_price}自动卖出 | 每#{show_period_sec(every_second)} | 每次¥#{sell_cny}元" if sell_over_price > 0
    # 选择高价价卖出
    result = "#{show_period(sell_when_minutes)}最高价|每#{show_period_sec(every_second)}|¥#{sell_cny}|最低卖价 #{min_sell_price}" if sell_when_minutes > 0
    result = "<u>#{result}</u>" if DealRecord.enable_to_sell? code
    return raw(result)
  end

end

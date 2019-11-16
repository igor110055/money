class ApplicationController < ActionController::Base

  include ApplicationHelper

  before_action :check_login, except: [ :login, :update_all_data ]
  before_action :summary, :memory_back, only: [ :index ]

  # 火币API初始化
  def ini_huobi
    [135,170].each do |pno|
      eval("@huobi_api_#{pno} = Huobi.new($acckey_#{pno},$seckey_#{pno},$accid_#{pno},$huobi_server)")
    end
  end

  # 初始化设置
  def initialize
    super
    load_global_variables
    ini_huobi # 初始化火币API
    Currency.add_or_renew_ex_rates # 方便汇率转换直接调用，无需再次查询数据库
  end

  # 读入网站所有的全局参数设定
  def load_global_variables
    eval(File.open("#{Rails.root}/config/global_variables.txt",'r').read)
  end

  # 所有页面需要输入PIN码登入之后才能使用
  def check_login
    redirect_to login_path if !login?
  end

  # 如果不是管理员则回到登入页重新登入
  def check_admin
    redirect_to login_path if !admin?
  end

  # 显示当前时间
  def now
    Time.now.strftime("%H:%M")
  end

  # 显示资产时是否包含显示隐藏资产
  def admin_hash( admin, new_options = {} )
    options = admin ? {include_hidden: true} : {include_hidden: false}
    return options.merge new_options
  end

  # 从火币网取得某一数字货币的最新报价
  def get_huobi_price( symbol )
    begin
      Timeout.timeout(90) do
        if @huobi_api_135
          root = @huobi_api_135.history_kline(symbol.to_s,'1min',1)
          if root["data"] and root["data"][0] # 不管什么情况，如果发生异常，则返回0
            return format("%.4f",root["data"][0]["close"]).to_f
          end
        end
      end
    rescue
      return 0
    end
  end

  # 更新所有数字货币的汇率值
  def update_digital_exchange_rates
    count = 0
    # 必须先更新USDT的汇率，其他的报价换算成美元才能准确
    usdt = Currency.usdt
    if usdt_price = get_huobi_price(usdt.symbol) and usdt_price > 0
      update_exchange_rate(usdt.code,(1/usdt_price).floor(8))
      count += 1
      Currency.digitals.each do |c|
        next if c.code == 'USDT'
        if price = get_huobi_price(c.symbol) and price > 0
          update_exchange_rate(c.code,(1/(price*usdt_price)).floor(8))
          count += 1
        end
      end
    end
    put_notice "#{count} #{t(:n_digital_exchange_rates_updated_ok)}" if count > 0
    return count
  end

  # 更新所有法币的汇率值
  def update_legal_exchange_rates
    count = 0
    Currency.legals.each do |c|
      code = c.code
      next if code == 'USD'
      if value = get_exchange_rate(:usd,code) and value > 0
        update_exchange_rate( code, value )
        count += 1
      end
    end
    put_notice "#{count} #{t(:n_legal_exchange_rates_updated_ok)}" if count > 0
    return count
  end

  # 更新所有的资料
  def update_all_data
    ori_login = admin? ? 'admin' : 'guest' # 远端必须以管理员身份存取，否则资产占比会出错
    session[:admin] = true
    update_yanda_house_price # 更新燕大星苑房屋单价
    update_all_huobi_assets # 更新火币所有账号的资产余额
    update_huobi_deal_records # 更新火币所有账号的交易记录
    update_digital_exchange_rates # 更新所有数字货币的汇率值
    update_portfolios_and_records # 更新所有的资产组合栏位数据和所有模型的数值记录
    go_back
    session[:admin] = ori_login == 'admin' ? true : false # 恢复原始登入身份
  end

  # 取得SSL连线的回传值
  def get_ssl_response( url, authorization = nil )
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = 180
    if url.split(':').first == 'https'
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    if authorization
      header = {'Authorization':authorization}
      response = http.get(url, header)
    else
      response = http.get(url)
    end
    return response.body
  end

  # 取得最新法币汇率的报价
  def get_exchange_rate( from_code, to_code )
    url = "https://ali-waihui.showapi.com/waihui-transform?fromCode=#{from_code.to_s.upcase}&toCode=#{to_code.to_s.upcase}&money=1"
    resp = get_ssl_response(url,"APPCODE de9f4a29c5eb4c73b0be619872e18857")
    if rate = Regexp.new(/(\d)+\.(\d)+/).match(resp)
      return rate[0].to_f
    else
      return 0
    end
  end

  # 更新单一货币的汇率值
  def update_exchange_rate( code, value )
    if currency = Currency.find_by_code(code)
      currency.update_attribute(:exchange_rate,value)
      return value
    end
  end

  # 记录返回的网址
  def memory_back( given_path = request.fullpath )
    session[:path] = params[:path] ? params[:path] : given_path
  end

  # 返回记录的网址
  def go_back
    if params[:path]
      redirect_to params[:path]
    elsif session[:path]
      redirect_to session[:path]
      session.delete(:path)
    end
  end

  # 在通知讯息后面加上物件的ID
  def add_id( object )
    " ID: #{object.id}"
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

  # 更新所有的资产组合栏位数据
  def update_all_portfolio_attributes
    Portfolio.all.each do |p|
      properties = get_properties_from_tags(p.include_tags,p.exclude_tags,p.mode)
      update_portfolio_attributes(p.id, properties)
    end
    put_notice t(:portfolios_updated_ok)
  end

  # 更新所有模型的数值记录
  def update_all_record_values
    properties_net_value_guest = Property.net_value :twd, admin_hash(false)
    properties_net_value_admin = Property.net_value :twd, admin_hash(true)
    $record_classes.each do |class_name|
      case class_name
        when 'NetValue'
          Property.record class_name, 1, properties_net_value_guest.to_i
        when 'NetValueAdmin'
          Property.record class_name, 1, properties_net_value_admin.to_i
        else
          eval(class_name).update_all_records
      end
    end
    put_notice t(:all_records_updated_ok)
  end

  # 更新资产组合栏位数据
  def update_portfolio_attributes( id, properties )
    twd_amount, cny_amount, proportion = get_portfolio_attributes(properties)
    Portfolio.find(id).update_attributes(
      twd_amount: twd_amount.to_i,
      cny_amount: cny_amount.to_i,
      proportion: proportion)
  end

  # 取得资产组合栏位数据
  def get_portfolio_attributes( properties )
    twd_amount = cny_amount = proportion = 0.0
    properties.each do |p|
      twd_amount += p.amount_to(:twd).to_i
      cny_amount += p.amount_to(:cny).to_i
      proportion += p.proportion(admin?).to_f
    end
    return [twd_amount, cny_amount, proportion]
  end

  # 获取资产的净值等统计数据
  def summary( admin = admin? )
    @show_summary = params[:tags] ? false : true
    @properties_net_value_twd = Property.net_value :twd, admin_hash(admin)
    @properties_net_value_cny = Property.net_value :cny, admin_hash(admin)
    @properties_lixi_twd = Property.lixi :twd, admin_hash(admin)
    @properties_value_twd = Property.value :twd, admin_hash(admin,only_positive: true)
    @properties_loan_twd = Property.value :twd, admin_hash(admin,only_negative: true)
    @properties_net_growth_ave_month = Property.net_growth_ave_month :twd, admin_hash(admin)
    # 访问资产负债表时能自动写入资产净值到数值记录表
    Property.record get_class_name_by_login, 1, @properties_net_value_twd.to_i
  end

  # 若以管理员登入则写入到NetValueAdmin否则NetValue
  def get_class_name_by_login
    admin? ? 'NetValueAdmin' : 'NetValue'
  end

  # 生成FusionCharts的XML资料的辅助方法
  def find_rec_date_value( records, date, value_field_name, rec_date_field_name )
    records.each do |r|
      return r.send(value_field_name) if r.send(rec_date_field_name).to_date.to_s(:db) == date.to_s(:db)
    end
    return nil
  end

  # 生成FusionCharts的XML资料
  def build_fusion_chart_data( class_name, oid )
    @name = class_name.index('Net') ? '资产总净值' : eval(class_name).find(oid).name
    records = Record.where(["class_name = ? and oid = ? and updated_at >= ?",class_name,oid,Date.today-$fusionchart_data_num.days]).order('updated_at')
    # 依照资料笔数的多寡来决定如何取图表中第一个值
    case records.size
      when 0
        last_record = Record.where(["class_name = ? and oid = ?",class_name,oid]).last
        last_value = last_record ? last_record.value : 0
      else
        last_value = records.first.value
    end
    @chart_data = ''
    today = Date.today
    start_date = today - $fusionchart_data_num.days
    data_arr = [] # 为了找出最大值和最小值
    start_date.upto(today) do |date|
      this_value = find_rec_date_value(records,date,'value','updated_at')
      if this_value
        value = this_value
        last_value = this_value
      else
        this_value = last_value
      end
      data_arr << this_value
      @chart_data += "<set label='#{date.strftime("%Y-%m-%d")}' value='#{this_value}' />"
    end
    # 设定最大值和最小值
    factor = 1.5 # 调整上下值，让图好看点，值越小离边界越近，不可小于1
    @min_value = data_arr.min
    @max_value = data_arr.max
    pos = @min_value < 1 ? 4 : 2 # 如果数值小于1，则显示小数点到4位，否则2位
    if @min_value == @max_value
      @top_value = to_n(@min_value*(1+(factor-1)),pos)
      @bottom_value = to_n(@min_value*(1-(factor-1)),pos)
    else
      mid_value = (@max_value + @min_value)/2
      center_diff = (@max_value - mid_value).abs #与中轴距离=最大值-中间值
      @top_value = to_n(mid_value + center_diff*factor,pos) #新最大值=中间值+与中轴距离*调整因子
      @bottom_value = to_n(mid_value - center_diff*factor,pos) #新最小值=中间值-与中轴距离*调整因子
    end
    @caption = "#{@name} #{$fusionchart_data_num}天走势图 ( #{@min_value} ➠ #{@max_value} )"
  end

  # 显示走势图
  def chart
    build_fusion_chart_data(self.class.name.sub('Controller','').singularize,params[:id])
    render template: 'shared/chart'
  end

  # 更新燕大星苑房屋单价
  def update_yanda_house_price
    # 安居客
    # url_1 = "https://qinhuangdao.anjuke.com/community/trends/387687"
    # pattern_1 = /\"comm_midprice\":\"(\d+)\"/
    # 房天下
    # url_2 = "https://yandaxingyuanhongshuwan.fang.com/"
    # pattern_2 = /var price = \"(\d+)\"/
    # 赶集网
    url = "http://qinhuangdao.ganji.com/xiaoqu/yandaxingyuanhongshuwan92JO/"
    pattern = /class=\"price\">(\d+)/
    code = get_ssl_response(url)
    if code and matches = Regexp.new(pattern).match(code).to_a and price = matches[1].to_i
      if price > 0
        Item.house.update_attribute(:price,price)
        put_notice t(:yanda_house_price_updated_ok)
      elsif code.empty?
        put_notice t(:source_empty)
      end
    end
  end

  # 连线读取火币账号的资产余额
  def get_huobi_assets( huobi_obj )
    root = huobi_obj.balances
    if root["status"] == "ok"
      result = []
      root["data"]["list"].each do |item|
        data = {}
        if item["balance"].to_f > 0.000000001
          data[:currency] = item["currency"]
          data[:type] = item["type"]
          data[:balance] = to_n(item["balance"].to_f,8)
          result << data
        end
      end
      return result
    else
      return nil
    end
  end

  # 合并trade与frozen两种type
  def sum_huobi_assets( arr )
    if arr and arr.size > 0
      result = []
      arr.each do |asset|
        data = {}; trade = frozen = 0
        trade = (arr.select {|a| a[:currency]==asset[:currency] and a[:type]=='trade'}).first[:balance].to_f
        if f = (arr.select {|a| a[:currency]==asset[:currency] \
            and a[:type]=='frozen'}) and f.size > 0
          frozen = f.first[:balance].to_f
        end
        data[:code] = asset[:currency].upcase
        data[:amount] = to_n(trade+frozen,8)
        result << data
      end
      return result
    end
  end

  # 更新火币所有账号的资产余额
  def update_all_huobi_assets
    count = 0
    ['135','170'].each do |pno|
    # 1.读取并整理火币资产数据成[{:code=>"husd",:amount=>"0.00005986"}]格式
      # 原始数据，包含trade与frozen两种type
      assets_arr_ori = get_huobi_assets(eval("@huobi_api_#{pno}"))
      # 合并trade与frozen两种type
      assets_arr_sum = sum_huobi_assets(assets_arr_ori)
    # 2.更新资产中相关的数据，若无则自动新增
      if assets_arr_sum and assets_arr_sum.size > 0
        properties = Property.tagged_with(pno)
        assets_arr_sum.each do |a|
          if property = (properties.select {|p| p.name.index(a[:code]) and p.name.index("火币资产 #{phone_number(pno)}")}.first)
            # 更新
            property.update_attribute(:amount,a[:amount])
            count += 1
          else
            # 新建
            Property.create(
              name: "火币资产 #{phone_number(pno)}: #{a[:code]}",
              amount: a[:amount],
              currency_id: get_or_create_currency(a[:code]),
              tag_list: pno
            )
            count += 1
          end
        end
      end
    end
    put_notice "#{count}#{t(:xiang)}#{t(:huobi_assets_updated_ok)}" if count > 0
    return count
  end

  # 更新火币所有账号的交易记录
  def update_huobi_deal_records
    count = 0
    symbol = 'btcusdt'
    ['135','170'].each do |pno|
      count += add_huobi_deal_records(eval("@huobi_api_#{pno}"),pno,symbol)
    end
    put_notice "#{count}#{t(:bi)}#{t(:huobi_deal_records_created_ok)}" if count > 0
    return count
  end

  # 连线读取火币账号的交易记录并自动新增
  def add_huobi_deal_records( huobi_obj, account, symbol )
    count = 0
    root = huobi_obj.history_matchresults(symbol)
    if root["status"] == "ok"
      root["data"].each do |data|
        data_id = data["id"]
        if !DealRecord.find_by_data_id(data_id)
          DealRecord.create(
            account: account,
            data_id: data_id,
            symbol: symbol,
            deal_type: data["type"],
            price: data["price"].to_f,
            amount: data["filled-amount"].to_f,
            fees: data["filled-fees"].to_f,
            earn_limit: 0,
            loss_limit: 0 )
          count += 1
        end
      end
    end
    return count
  end

  # 更新所有的资产组合栏位数据和所有模型的数值记录
  def update_portfolios_and_records
    update_all_portfolio_attributes # 更新所有的资产组合栏位数据
    update_all_record_values # 更新所有模型的数值记录
  end

  # 获取手机号码
  def phone_number( pno )
    case pno.to_s
      when '135' then return '13581706025'
      when '170' then return '17099311026'
    end
  end

  # 获取货币识别ID，若无则新增
  def get_or_create_currency( code )
    if currency = Currency.find_by_code(code)
      return currency.id
    else
      new_currency = Currency.create(
        name: code.capitalize,
        code: code,
        symbol: "#{code.downcase}usdt",
        exchange_rate: 1.0
      )
      return new_currency.id
    end
  end

  # 建立回到目录页的方法
  $models.each do |n|
    define_method "go_#{n.pluralize}" do
      eval("redirect_to controller: :#{n.pluralize}, action: :index")
    end
  end

  # 建立各种通知消息的方法
  $flashs.each do |type|
    define_method "put_#{type}" do |msg|
      eval %Q[
        flash[:#{type}] ? flash[:#{type}].gsub!(\"(\#{now})\",'') : flash[:#{type}] = ''
        flash[:#{type}] += \"\#{msg} (\#{now})\"
      ]
    end
  end

  # 建立从列表中快速更新某个值的方法
  $quick_update_attrs.each do |setting|
    m = setting.split(':')[0]; attrs = setting.split(':')[1].split(',')
    attrs.each do |a|
      define_method "update_#{m}_#{a}" do
        eval %Q[
          if new_#{a} = params[\"new_#{a}_\#{params[:id]}\"]
            @#{m}.update_attribute(:#{a}, new_#{a})
            put_notice t(:#{m}_updated_ok) + add_id(@#{m})
          end
          session[:path] ? go_back : go_#{m.pluralize}
        ]
      end
    end
  end

end

class CurrenciesController < ApplicationController

  before_action :set_currency, only: [:edit, :update, :update_exchange_rate_from_to_usd, :destroy, :delete]

  # 货币列表
  def index
    @currencies = Currency.all
  end

  # 新建货币表单
  def new
    @currency = Currency.new
  end

  # 编辑货币表单
  def edit
  end

  # 新建货币
  def create
    @currency = Currency.new(currency_params)
    if @currency.save
      put_notice t(:currency_created_ok) + do_sync_create_currency
      go_currencies
    else
      render :new
    end
  end

  # 同步另一台服务器的新建货币
  def do_sync_create_currency
    send_sync_request "#{$host2}sync_create_currency.json#{url_params}"
  end

  # 新增货币能同步更新两台服务器
  def sync_create_currency
    sync_host(Currency,nil,true) do
      if !Currency.find_by_code(params[:sync_code].upcase)
        Currency.new(data_params).save
      end
    end
  end

  # 更新货币
  def update
    if @currency.update(currency_params)
      put_notice t(:currency_updated_ok) + ' ' + do_sync_update_currency
      go_currencies
    else
      render :edit
    end
  end

  # 同步另一台服务器的货币
  def do_sync_update_currency
    send_sync_request "#{$host2}sync_update_currency.json#{url_params}"
  end

# 由外部链接而来更新资产
  def sync_update_currency
    sync_host(Currency,'code',false,true) do
      @rs.update_attributes(data_params)
    end
  end

  # 更新所有货币的汇率值
  def update_all_exchange_rates
    update_exchange_rates
    go_back
  end

  # 更新比特币及以太坊的汇率值
  def update_btc_exchange_rates
    put_notice t(:get_price_error) if !(update_digital_exchange_rates > 0)
    go_back
  end

  # 更新所有数字货币的汇率值
  def update_all_digital_exchange_rates
    begin
      if !(update_digital_exchange_rates(true) > 0)
        put_notice t(:get_price_error)
      end
    rescue Net::OpenTimeout
      put_notice 'Execution Expired Error!'
    end
    go_currencies
  end

  # 更新所有法币的汇率值
  def update_all_legal_exchange_rates
    update_legal_exchange_rates
    go_back
  end

  # 删除货币
  def destroy
    @currency.destroy
    put_notice t(:currency_destroyed_ok) + do_sync_destroy_currency(@currency.code)
    go_currencies
  end

  # 同步另一台服务器的删除货币
  def do_sync_destroy_currency( sync_code )
    send_sync_request "#{$host2}sync_destroy_currency.json?key=#{$api_key}&sync_code=#{sync_code}"
  end

  # 由外部链接而来删除货币
  def sync_destroy_currency
    sync_host(Currency,'code',false,true) do
      @rs.destroy
    end
  end

  # 删除货币
  def delete
    destroy
  end

  # 通过输入框直接更新比特币价格
  def update_exchange_rate_from_to_usd
    params["new_exchange_rate_#{params[:id]}"] = (1/params["new_exchange_rate_#{params[:id]}"].to_f).to_s
    update_currency_exchange_rate
  end

  private

    # 取出特定的某笔数据
    def set_currency
      @currency = Currency.find(params[:id])
    end

    # 设定栏位安全白名单
    def currency_params
      if admin?
        params.require(:currency).permit(:name, :code, :symbol, :exchange_rate, :auto_update_price)
      else
        params.require(:currency).permit(:name, :code, :exchange_rate, :auto_update_price)
      end
    end

    # 组成网址参数
    def url_params
      "?key=#{$api_key}&sync_code=#{params[:currency][:code].downcase}&name=#{u(params[:currency][:name])}&code=#{params[:currency][:code]}&exchange_rate=#{params[:currency][:exchange_rate]}&symbol=#{params[:currency][:symbol]}&auto_update_price=#{params[:currency][:auto_update_price]}"
    end

    # 组成数据库参数
    def data_params
      {
        name: params[:name],
        code: params[:code],
        exchange_rate: params[:exchange_rate],
        symbol: params[:symbol],
        auto_update_price: params[:auto_update_price]
      }
    end

end

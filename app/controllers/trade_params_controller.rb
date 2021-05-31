class TradeParamsController < ApplicationController

  before_action :check_admin
  before_action :set_trade_param, only: [:edit, :update, :destroy, :delete]

  def index
    @trade_params = TradeParam.all
  end

  def show
  end

  def new
    @trade_param = TradeParam.new
    @trade_param.order_num = TradeParam.all.size+1
  end

  def edit
  end

  def create
    @trade_param = TradeParam.new(trade_param_params)
    if @trade_param.save
      put_notice "交易参数已成功新增！#{sync_attributes}"
      go_trade_params
    else
      render :new
    end
  end

  def update
    if @trade_param.update(trade_param_params)
      put_notice "交易参数已成功更新！#{sync_attributes}"
      go_trade_params
    else
      render :edit
    end
  end

  # 同步另一台服务器的值
  def sync_attributes
    send_sync_request "#{$host2}main/sync_trade_params.json?key=#{$api_key}&sync_code=#{params[:trade_param][:name].downcase}&title=#{u(params[:trade_param][:title])}&order_num=#{params[:trade_param][:order_num]}"
  end

  def destroy
    @trade_param.destroy
    put_notice "交易参数已成功删除！"
    go_trade_params
  end

  def delete
    destroy
  end

  private

    def set_trade_param
      @trade_param = TradeParam.find(params[:id])
    end

    def trade_param_params
      params.require(:trade_param).permit(:name, :title, :order_num)
    end

end

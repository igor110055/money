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
  end

  def edit
  end

  def create
    @trade_param = TradeParam.new(trade_param_params)
    if @trade_param.save
      put_notice "交易参数已成功新增！"
      go_trade_params
    else
      render :new
    end
  end

  def update
    if @trade_param.update(trade_param_params)
      put_notice "交易参数已成功更新！"
      go_trade_params
    else
      render :edit
    end
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

class TradeParamsController < ApplicationController

  before_action :check_admin
  before_action :set_trade_param, only: [:edit, :update, :destroy, :delete, :order_up, :order_down]

  def index
    @trade_params = TradeParam.all.order(:order_num)
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
    send_sync_request "#{sync_root}&title=#{u(params[:trade_param][:title])}&order_num=#{params[:trade_param][:order_num]}"
  end

  # 能同步删除两台服务器的交易参数
  def sync_destroy
    send_sync_request "#{sync_root}&destroy=1"
  end

  # 点击交易参数列表的上下箭头能同步更新两台服务器参数的显示顺序
  def sync_order_up
    send_sync_request "#{sync_root}&order_up=1"
  end

  # 点击交易参数列表的上下箭头能同步更新两台服务器参数的显示顺序
  def sync_order_down
    send_sync_request "#{sync_root}&order_down=1"
  end

  def destroy
    put_notice "交易参数已成功删除！#{sync_destroy}"
    @trade_param.destroy
    go_trade_params
  end

  def delete
    destroy
  end

  def order_up
    exe_order_up TradeParam, params[:id]
    put_notice "交易参数已成功排序！#{sync_order_up}"
    go_trade_params
  end

  def order_down
    exe_order_down TradeParam, params[:id]
    put_notice "交易参数已成功排序！#{sync_order_down}"
    go_trade_params
  end

  private

    def set_trade_param
      @trade_param = TradeParam.find(params[:id])
    end

    def trade_param_params
      params.require(:trade_param).permit(:name, :title, :order_num)
    end

    def sync_root
      "#{$host2}main/sync_trade_params.json?key=#{$api_key}&sync_code=#{@trade_param.name.downcase}"
    end

end

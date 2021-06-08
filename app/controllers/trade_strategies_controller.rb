class TradeStrategiesController < ApplicationController

    before_action :check_admin
    before_action :set_trade_strategy, only: [:edit, :update, :destroy, :delete]

    def index
      @trade_strategies = TradeStrategy.all
    end

    def new
      @trade_strategy = TradeStrategy.new
    end

    def edit
      @trade_strategy.range_step = @trade_strategy.trade_param.default_range_step if @trade_strategy.range_step.empty?
    end

    def create
      @trade_strategy = TradeStrategy.new(trade_strategy_params)
      if @trade_strategy.save
        put_notice "交易策略已成功新增！#{sync_attributes}"
        go_trade_strategies
      else
        render :new
      end
    end

    def update
      if @trade_strategy.update(trade_strategy_params)
        put_notice "交易策略已成功更新！#{sync_attributes}"
        go_trade_strategies
      else
        render :edit
      end
    end

    # 同步另一台服务器的值
    def sync_attributes
      send_sync_request "#{sync_root}&deal_type=#{params[:trade_strategy][:deal_type]}&param_value=#{params[:trade_strategy][:param_value]}&range_step=#{params[:trade_strategy][:range_step]}&trade_param_id=#{params[:trade_strategy][:trade_param_id]}"
    end

    # 能同步删除两台服务器的交易策略
    def sync_destroy
      send_sync_request "#{sync_root}&destroy=1"
    end

    def destroy
      @trade_strategy.destroy
      put_notice "交易策略已成功删除！#{sync_destroy}"
      go_trade_strategies
    end

    def delete
      destroy
    end

  private

    def set_trade_strategy
      @trade_strategy = TradeStrategy.find(params[:id])
    end

    def trade_strategy_params
      params.require(:trade_strategy).permit(:deal_type, :param_value, :range_step, :trade_param_id)
    end

    def sync_root
      "#{$host2}sync_tstrategy_info.json?key=#{$api_key}&sync_code=#{[@trade_strategy.deal_type,@trade_strategy.trade_param_id].join(',')}"
    end

end

class DigitalParamsController < ApplicationController

    before_action :check_admin
    before_action :set_digital_param, only: [:edit, :update, :destroy, :delete]

    def index
      @digital_params = DigitalParam.all
    end

    def new
      @digital_param = DigitalParam.new
    end

    def edit
    end

    def create
      @digital_param = DigitalParam.new(digital_param_params)
      if @digital_param.save
        put_notice "交易对参数已成功新增！#{sync_attributes}"
        go_digital_params
      else
        render :new
      end
    end

    def update
      if @digital_param.update(digital_param_params)
        put_notice "交易对参数已成功更新！#{sync_attributes}"
        go_digital_params
      else
        render :edit
      end
    end

    # 同步另一台服务器的值
    def sync_attributes
      send_sync_request "#{sync_root}&symbol=#{params[:digital_param][:symbol]}&deal_type=#{params[:digital_param][:deal_type]}&param_name=#{params[:digital_param][:param_name]}&param_value=#{params[:digital_param][:param_value]}"
    end

    # 能同步删除两台服务器的交易对参数
    def sync_destroy
      send_sync_request "#{sync_root}&destroy=1"
    end

    def destroy
      @digital_param.destroy
      put_notice "交易对参数已成功删除！#{sync_destroy}"
      go_digital_params
    end

    def delete
      destroy
    end

  private

    def set_digital_param
      @digital_param = DigitalParam.find(params[:id])
    end

    def digital_param_params
      params.require(:digital_param).permit(:symbol,:deal_type,:param_name,:param_value)
    end

    def sync_root
      "#{$host2}sync_digital_param.json?key=#{$api_key}&sync_code=#{[@digital_param.symbol,@digital_param.deal_type,@digital_param.param_name].join(',')}"
    end

end

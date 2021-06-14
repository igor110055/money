class DigitalCurrenciesController < ApplicationController

    before_action :check_admin
    before_action :set_digital_currency, only: [:edit, :update, :destroy, :delete]

    def index
      @digital_currencies = DigitalCurrency.all
    end

    def new
      @digital_currency = DigitalCurrency.new
    end

    def edit
    end

    def create
      @digital_currency = DigitalCurrency.new(digital_currency_params)
      if @digital_currency.save
        put_notice "交易对已成功新增！#{sync_attributes}"
        go_digital_currencies
      else
        render :new
      end
    end

    def update
      if @digital_currency.update(digital_currency_params)
        put_notice "交易对已成功更新！#{sync_attributes}"
        go_digital_currencies
      else
        render :edit
      end
    end

    # 同步另一台服务器的值
    def sync_attributes
      send_sync_request "#{sync_root}&symbol_from=#{params[:digital_currency][:symbol_from]}&symbol_to=#{params[:digital_currency][:symbol_to]}"
    end

    # 能同步删除两台服务器的交易对
    def sync_destroy
      send_sync_request "#{sync_root}&destroy=1"
    end

    def destroy
      @digital_currency.destroy
      put_notice "交易对已成功删除！#{sync_destroy}"
      go_digital_currencies
    end

    def delete
      destroy
    end

  private

    def set_digital_currency
      @digital_currency = DigitalCurrency.find(params[:id])
    end

    def digital_currency_params
      params.require(:digital_currency).permit(:symbol_from,:symbol_to)
    end

    def sync_root
      "#{$host2}sync_digital_currency.json?key=#{$api_key}&sync_code=#{[@digital_currency.symbol_from,@digital_currency.symbol_to].join(',')}"
    end

end

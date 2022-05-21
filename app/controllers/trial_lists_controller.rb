class TrialListsController < ApplicationController

    before_action :set_trial_list, only: [:edit, :update, :destroy, :delete]

    # 输入比特币每月增长利率以及每月生活费计算能维持多少年
    def index
      exe_auto_update_prices if $auto_update_btc_price > 0 # 执行自动更新报价
      update_huobi_assets_core if $auto_update_huobi_assets > 0
      prepare_price_vars
    end

    def new
    end

    def edit
    end

    def create
    end

    def update
    end

    def destroy
    end

    def save_trials_to_db
      put_notice t(:save_trials_to_db_ok)
      redirect_to action: :index, exe_save_trials_to_db: 'yes'
    end

    private

      def set_trial_list
        @trial_list = TrialList.find(params[:id])
      end

      def trial_list_params
        params.require(:trial_list).permit(:trial_date, :begin_price, :begin_amount, :month_cost, :month_sell, :begin_balance, :begin_balance_twd, :month_grow_rate, :end_price, :end_balance, :end_balance_twd)
      end

end

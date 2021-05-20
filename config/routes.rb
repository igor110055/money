Rails.application.routes.draw do

  resources :trial_lists
  root 'deal_records#index_btc'

  resources :properties do
    member do
      get :update_amount, :chart, :delete
    end
  end
  resources :items do
    member do
      get :update_price, :update_amount, :chart, :delete
    end
  end
  resources :portfolios do
    member do
      get :order_up, :order_down, :chart, :delete
    end
  end
  resources :currencies do
    member do
      get :update_exchange_rate_from_to_usd, :chart, :delete
    end
  end
  resources :interests do
    member do
      get :chart, :delete
    end
  end
  resources :records do
    member do
      get :delete
    end
  end
  resources :deal_records do
    member do
      get :delete, :switch_first_sell, :switch_to_trezor, :switch_to_balance
    end
  end
  resources :open_orders do
    member do
      get :delete
    end
  end

  get '/login', to: 'main#login'
  get '/logout', to: 'main#logout'
  get '/net_chart', to: 'main#net_chart'
  get '/net_chart_fix', to: 'records#net_chart_fix'
  get 'update_huobi_data', to: 'main#update_huobi_data'
  get 'flow_assets', to: 'properties#show_flow_assets'
  get 'update_all_data', to: 'properties#update_all_data'
  get 'update_all_exchange_rates', to: 'currencies#update_all_exchange_rates'
  get 'update_all_legal_exchange_rates', to: 'currencies#update_all_legal_exchange_rates'
  get 'update_all_digital_exchange_rates', to: 'currencies#update_all_digital_exchange_rates'
  get 'update_btc_exchange_rates', to: 'currencies#update_btc_exchange_rates'
  get 'update_all_portfolios', to: 'portfolios#update_all_portfolios'
  get 'update_house_price', to: 'items#update_house_price'
  get 'deal_records_btc', to: 'deal_records#index_btc'
  get 'deal_records_eth', to: 'deal_records#index_eth'
  get 'delete_btc_deal_record', to: 'deal_records#delete_btc'
  get 'clear_btc_deal_records', to: 'deal_records#clear_btcs'
  get 'delete_eth_deal_record', to: 'deal_records#delete_eth'
  get 'clear_eth_deal_records', to: 'deal_records#clear_eths'
  get 'delete_eth_deal_record_then_add_usdt', to: 'deal_records#delete_eth_then_add_usdt'
  get 'clear_eths_deal_record_then_add_usdt', to: 'deal_records#clear_eths_then_add_usdt'
  get 'clear_deal_records', to: 'deal_records#clear'
  get 'auto_send_trezor_count', to: 'deal_records#auto_send_trezor_count'
  get 'auto_send_balance_count', to: 'deal_records#auto_send_balance_count'
  get 'delete_invest_log', to: 'deal_records#delete_invest_log'
  get 'update_deal_records', to: 'deal_records#update_deal_records'
  get 'zip_sell_records', to: 'deal_records#zip_sell_records'
  get 'send_sell_deal_records', to: 'deal_records#send_sell_deal_records'
  get 'send_stop_loss', to: 'deal_records#send_stop_loss'
  get 'send_force_buy', to: 'deal_records#send_force_buy'
  get 'sell_to_back', to: 'deal_records#sell_to_back'
  get 'set_btc_as_home', to: 'deal_records#set_btc_as_home'
  get 'set_sbtc_as_home', to: 'deal_records#set_sbtc_as_home'
  get 'set_eth_as_home', to: 'deal_records#set_eth_as_home'
  get 'update_huobi_assets', to: 'main#update_huobi_assets'
  get 'update_huobi_records', to: 'main#update_huobi_records'
  get 'place_order_form', to: 'main#place_order_form'
  get 'look_order', to: 'main#look_order'
  post 'place_order', to: 'main#place_order'
  post 'order_calculate', to: 'main#order_calculate'
  get 'invest_log', to: 'main#read_auto_invest_log'
  get 'invest_eth_log', to: 'main#read_auto_invest_eth_log'
  get 'set_auto_invest_form', to: 'main#set_auto_invest_form'
  get 'set_auto_invest_btc_form', to: 'main#set_auto_invest_btc_form'
  get 'set_auto_invest_eth_form', to: 'main#set_auto_invest_eth_form'
  post 'set_auto_invest_params', to: 'main#set_auto_invest_params'
  post 'set_auto_invest_btc_params', to: 'main#set_auto_invest_btc_params'
  post 'set_auto_invest_eth_params', to: 'main#set_auto_invest_eth_params'
  get 'setup_invest_param', to: 'main#setup_invest_param'
  get 'setup_invest_eth_param', to: 'main#setup_invest_eth_param'
  get 'system_params_form', to: 'main#system_params_form'
  post 'update_system_params', to: 'main#update_system_params'
  get 'test_huobi', to: 'main#get_huobi_assets_test'
  get 'kdata', to: 'main#kline_data'
  get 'mtrades', to: 'main#model_trade_test_set'
  get 'mtrades_log', to: 'main#show_mtrades_log'
  get 'mtrade', to: 'main#model_trade_test_single'
  get 'mtrade_log', to: 'main#show_mtrade_log'
  get 'save_kdata', to: 'main#save_kline_data'
  get 'sell_btc_amount_as_huobi', to: 'main#sell_btc_amount_as_huobi'
  get 'sell_eth_amount_as_huobi', to: 'main#sell_eth_amount_as_huobi'
  get 'check_open_order', to: 'open_orders#check_open_order'
  get 'clear_open_orders', to: 'open_orders#clear'
  get 'huobi_assets', to: 'properties#huobi_assets'
  get 'save_trials_to_db', to: 'trial_lists#save_trials_to_db'
  get 'switch_show_value_cur', to: 'main#switch_show_value_cur'
  %w(auto_update_btc_price auto_update_huobi_assets auto_refresh_sec).each do |name|
    get "switch_#{name}", to: "main#switch_#{name}"
  end
  get 'rename_tag', to: 'main#rename_tag'
  post 'update_tag_name', to: 'main#update_tag_name'
  get 'main/del_huobi_orders'
  get 'main/kline_chart'
  get 'main/line_chart'
  get 'main/rise_fall_list'
  get 'main/level_trial_list'

end

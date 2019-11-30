Rails.application.routes.draw do

  root 'properties#index'

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
      get :chart, :delete
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
      get :delete
    end
  end

  get '/login', to: 'main#login'
  get '/logout', to: 'main#logout'
  get '/chart', to: 'main#chart'
  get 'update_huobi_data', to: 'main#update_huobi_data'
  get 'update_all_data', to: 'properties#update_all_data'
  get 'update_all_exchange_rates', to: 'currencies#update_all_exchange_rates'
  get 'update_all_legal_exchange_rates', to: 'currencies#update_all_legal_exchange_rates'
  get 'update_all_digital_exchange_rates', to: 'currencies#update_all_digital_exchange_rates'
  get 'update_btc_exchange_rates', to: 'currencies#update_btc_exchange_rates'
  get 'update_all_portfolios', to: 'portfolios#update_all_portfolios'
  get 'update_house_price', to: 'items#update_house_price'
  get 'clear_deal_records', to: 'deal_records#clear'
  get 'update_huobi_assets', to: 'main#update_huobi_assets'
  get 'update_huobi_records', to: 'main#update_huobi_records'
  get 'place_order_confirm', to: 'main#place_order_confirm'
  get 'look_order', to: 'main#look_order'
  post 'place_order', to: 'main#place_order'
  get 'main/get_huobi_assets_test'
  get 'main/del_huobi_orders'

end

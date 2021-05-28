class TradeParam < ApplicationRecord

  validates \
    :name,
      presence: {
        message: $trade_param_name_blank_err }
  validates \
    :title,
      presence: {
        message: $trade_param_title_blank_err }          
end

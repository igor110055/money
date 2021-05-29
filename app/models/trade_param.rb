class TradeParam < ApplicationRecord

  validates \
    :name,
      presence: {
        message: $trade_param_name_blank_err }
  validates \
    :title,
      presence: {
        message: $trade_param_title_blank_err }
  validates \
    :order_num,
      presence: {
        message: $trade_param_order_num_blank_err },
      numericality: {
        message: $trade_param_order_num_numerical_err }
  validates \
    :order_num,
      numericality: {
        greater_than: 0,
        message: $trade_param_order_num_format_err }

end

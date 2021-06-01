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
    :param_type,
      presence: {
        message: $trade_param_type_blank_err }
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

  def type_label
    if param_type
      trade_param_type_arr.rassoc(param_type)[0]
    else
      "unset"
    end
  end

  def order_up
    exe_order_up TradeParam, id
  end

  def order_down
    exe_order_down TradeParam, id
  end

end

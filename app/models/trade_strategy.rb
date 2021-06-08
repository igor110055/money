class TradeStrategy < ApplicationRecord

  belongs_to :trade_param

  validates \
    :deal_type,
      presence: {
        message: $trade_strategy_deal_type_blank_err }
  validates \
    :param_value,
      presence: {
        message: $trade_strategy_param_value_blank_err }
  validates \
    :trade_param_id,
      presence: {
        message: $trade_strategy_trade_param_id_blank_err }

end

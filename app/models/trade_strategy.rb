class TradeStrategy < ApplicationRecord

  belongs_to :trade_param
  before_validation :set_trade_param_id

  validates \
    :deal_type,
      presence: {
        message: $trade_strategy_deal_type_blank_err }
  validates \
    :param_name,
      presence: {
        message: $trade_strategy_param_name_blank_err }
  validates \
    :param_value,
      presence: {
        message: $trade_strategy_param_value_blank_err }
  validates \
    :trade_param_id,
      presence: {
        message: $trade_strategy_trade_param_id_blank_err }

  def set_trade_param_id
      self.trade_param_id = TradeParam.find_by_name(param_name).id if TradeParam.find_by_name(param_name)
  end

end

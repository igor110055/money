class DigitalParam < ApplicationRecord
  belongs_to :trade_param
  before_validation :set_trade_param_id

  validates \
    :symbol,
      presence: {
        message: $digital_param_symbol_blank_err }
  validates \
    :deal_type,
      presence: {
        message: $digital_param_deal_type_blank_err }
  validates \
    :param_name,
      presence: {
        message: $digital_param_name_blank_err }
  validates \
    :param_value,
      presence: {
        message: $digital_param_value_blank_err }

  validates :symbol, uniqueness: { scope: [:deal_type, :param_name], message: $digital_param_key_repeat_err }

end

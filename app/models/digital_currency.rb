class DigitalCurrency < ApplicationRecord

  before_validation :set_symbol

  validates_uniqueness_of :symbol, message: $digital_currency_symbol_repeat_err

  validates \
    :symbol_from,
      presence: {
        message: $digital_currency_symbol_from_blank_err }
  validates \
    :symbol_to,
      presence: {
        message: $digital_currency_symbol_to_blank_err }

  def set_symbol
    self.symbol = (self.symbol_from + self.symbol_to).downcase if self.symbol_from and self.symbol_to
  end

end

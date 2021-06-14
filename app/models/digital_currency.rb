class DigitalCurrency < ApplicationRecord

  validates \
    :symbol_from,
      presence: {
        message: $digital_currency_symbol_from_blank_err }
  validates \
    :symbol_to,
      presence: {
        message: $digital_currency_symbol_to_blank_err }

end

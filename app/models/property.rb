class Property < ApplicationRecord

  belongs_to :currency

  validates \
    :name,
      presence: {
        message: $property_name_blank_err },
      length: {
        maximum: $property_name_maxlength,
        message: $property_name_len_err }

  validates \
    :amount,
      presence: {
        message: $property_amount_blank_err },
      numericality: {
        message: $property_amount_nan_err }

  # 将资产金额从自身的币别转换成其他币别(默认为新台币)
  def amount_to( target_code = :twd )
    target_exchange_rate = eval "$#{target_code.to_s.downcase}_exchange_rate"
    if target_exchange_rate
      return amount*(target_exchange_rate.to_f/self.currency.exchange_rate.to_f)
    else
      return amount
    end
  end

end

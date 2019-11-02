class Item < ApplicationRecord

  belongs_to :property

  validates \
    :price,
      presence: {
        message: $item_price_blank_err },
      numericality: {
        greater_than_or_equal_to: 0,
        message: $item_price_type_err }

  validates \
    :amount,
      presence: {
        message: $item_amount_blank_err },
      numericality: {
        greater_than_or_equal_to: 0,
        message: $item_amount_type_err }

  after_save :update_property_amount

  # 更新对应的资产金额
  def update_property_amount
    ori_amount = property.amount.to_i
    new_amount = (price * amount).to_i
    if new_amount - ori_amount != 0
      property.update_amount(new_amount)
      return true
    else
      return false
    end
  end

end

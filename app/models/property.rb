class Property < ApplicationRecord

  validates :name,
    presence: { message: $property_name_error_by_blank },
    length: { maximum: $property_name_maxlength, message: $property_name_error_by_length }
  validates :amount,
    presence: { message: $property_amount_error_by_blank },
    numericality: {  greater_than_or_equal_to: 0, message: $property_amount_error_by_numeric }

end

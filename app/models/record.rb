class Record < ApplicationRecord

  validates \
    :class_name,
      presence: {
        message: $record_class_name_blank_err }
  validates \
    :oid,
      presence: {
        message: $record_oid_blank_err }
  validates \
    :value,
      presence: {
        message: $record_value_blank_err },
      numericality: {
        message: $record_value_nan_err }


  # 资产净值变化值
  def self.net_value_change_from( date = Date.today - 1.month )
    begin
      begin_value = where(["class_name = ? and oid = ? and updated_at > ? and updated_at < ? ",'NetValueAdmin',1,date,date+10.day]).first.value
    rescue
      begin_value = $net_start_value
    end
    begin
      end_value = where(["class_name = ? and oid = ?",'NetValueAdmin',1]).order('updated_at desc').limit(1).first.value
    rescue
      end_value = $net_start_value
    end
    diff_value = end_value - begin_value
    diff_rate = (diff_value/begin_value)*100
    return diff_value.to_i, diff_rate.floor(2)
  end

end

class AddTradeParamReferencesToDigitalParams < ActiveRecord::Migration[5.2]
  def change
    add_reference :digital_params, :trade_param, foreign_key: true
  end
end

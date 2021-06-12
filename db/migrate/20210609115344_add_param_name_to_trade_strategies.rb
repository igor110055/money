class AddParamNameToTradeStrategies < ActiveRecord::Migration[5.2]
  def change
    add_column :trade_strategies, :param_name, :string
  end
end

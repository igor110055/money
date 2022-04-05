class RemoveSymbolFromTradeStrategies < ActiveRecord::Migration[5.2]
  def change
    remove_column :trade_strategies, :symbol, :string
  end
end

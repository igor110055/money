class AddTypeToTradeParams < ActiveRecord::Migration[5.2]
  def change
    add_column :trade_params, :param_type, :string
    add_column :trade_params, :default_range_step, :string
  end
end

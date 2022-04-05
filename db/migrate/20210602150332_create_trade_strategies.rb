class CreateTradeStrategies < ActiveRecord::Migration[5.2]
  def change
    create_table :trade_strategies do |t|
      t.string :symbol
      t.string :deal_type
      t.string :param_value
      t.string :range_step
      t.references :trade_param, foreign_key: true

      t.timestamps
    end
  end
end

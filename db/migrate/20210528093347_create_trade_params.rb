class CreateTradeParams < ActiveRecord::Migration[5.2]
  def change
    create_table :trade_params do |t|
      t.string :name
      t.string :title
      t.integer :order_num

      t.timestamps
    end
  end
end

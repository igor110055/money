class AddColumnToCurrencies < ActiveRecord::Migration[5.2]
  def change
    add_column :currencies, :auto_update_price, :boolean
  end
end

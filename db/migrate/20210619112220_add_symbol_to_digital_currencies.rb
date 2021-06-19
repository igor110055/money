class AddSymbolToDigitalCurrencies < ActiveRecord::Migration[5.2]
  def change
    add_column :digital_currencies, :symbol, :string
  end
end

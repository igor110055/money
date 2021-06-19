class CreateDigitalCurrencies < ActiveRecord::Migration[5.2]
  def change
    create_table :digital_currencies do |t|
      t.string :symbol_from
      t.string :symbol_to

      t.timestamps
    end
  end
end

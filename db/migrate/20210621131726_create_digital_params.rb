class CreateDigitalParams < ActiveRecord::Migration[5.2]
  def change
    create_table :digital_params do |t|
      t.string :symbol
      t.string :deal_type
      t.string :param_name
      t.string :param_value

      t.timestamps
    end
  end
end

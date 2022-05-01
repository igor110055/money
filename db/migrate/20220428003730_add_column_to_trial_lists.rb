class AddColumnToTrialLists < ActiveRecord::Migration[5.2]
  def change
    add_column :trial_lists, :month_invest, :integer
  end
end

class AddSyncCodeToProperties < ActiveRecord::Migration[5.2]
  def change
    add_column :properties, :sync_code, :string
  end
end

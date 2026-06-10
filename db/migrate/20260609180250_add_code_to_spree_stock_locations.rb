class AddCodeToSpreeStockLocations < ActiveRecord::Migration[7.2]
  def change
    add_column :spree_stock_locations, :code, :string, if_not_exists: true
  end
end

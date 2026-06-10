class AddCodeToSpreeStockLocations < ActiveRecord::Migration[7.2]
  def change
    return if column_exists? :spree_stock_locations, :code

    add_column :spree_stock_locations, :code, :string
  end
end

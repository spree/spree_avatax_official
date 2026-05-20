class AddAvataxCompanyCodeToSpreeStores < ActiveRecord::Migration[7.2]
  def change
    return unless table_exists? :spree_stores
    return if column_exists? :spree_stores, :avatax_company_code

    add_column :spree_stores, :avatax_company_code, :string
  end
end

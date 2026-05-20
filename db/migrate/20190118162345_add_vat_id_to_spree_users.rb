class AddVatIdToSpreeUsers < ActiveRecord::Migration[7.2]
  def change
    return if column_exists?(:spree_users, :vat_id)

    add_column :spree_users, :vat_id, :string
  end
end

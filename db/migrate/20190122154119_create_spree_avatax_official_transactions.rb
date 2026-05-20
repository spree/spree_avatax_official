class CreateSpreeAvataxOfficialTransactions < ActiveRecord::Migration[7.2]
  def change
    create_table :spree_avatax_official_transactions do |t|
      t.references :order,             null: false, index: true
      t.string     :transaction_type,  null: false, index: true
      t.string     :code,              null: false, index: { unique: true }
      t.timestamps
    end
  end
end

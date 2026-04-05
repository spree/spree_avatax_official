class CreateSpreeAvataxOfficialEntityUseCodesTable < ActiveRecord::Migration[7.2]
  def change
    create_table :spree_avatax_official_entity_use_codes do |t|
      t.string          :code, null: false, index: { unique: true }
      t.string          :name, null: false, index: { unique: true }

      t.text            :description

      t.timestamps
    end

    return if column_exists?(:spree_users, :avatax_entity_use_code_id)

    add_column :spree_users, :avatax_entity_use_code_id, :integer
    add_index :spree_users, :avatax_entity_use_code_id, unique: true
  end
end

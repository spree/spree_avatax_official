class CreateSpreeAvalaraEntityUseCodes < ActiveRecord::Migration[7.2]
  def change
    return if table_exists?(:spree_avalara_entity_use_codes)

    create_table :spree_avalara_entity_use_codes do |t|
      t.string :use_code
      t.string :use_code_description
      t.timestamps
    end
  end
end

class AddAvalaraEntityUseCodeReferenceToUsers < ActiveRecord::Migration[7.2]
  def change
    return if column_exists?(:spree_users, :avalara_entity_use_code_id)

    add_reference :spree_users, :avalara_entity_use_code, index: true
  end
end

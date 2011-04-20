class CreateAuthorizations < ActiveRecord::Migration
  def self.up
    create_table :authorize_permissions, :force => true do |t|
      t.references :role, :null => false
      t.references :resource, :polymorphic => true
      t.integer :mask, :limit => 255, :default => 1, :null => false
      t.datetime :updated_at
    end
    add_index :authorize_permissions, [:role_id, :resource_id, :resource_type], :unique => true, :name => "index_authorize_permissions_on_role_id_and_resource"
    add_index :authorize_permissions, [:resource_id, :resource_type, :role_id], :unique => true, :name => "index_authorize_permissions_on_resource_and_role_id"

    create_table :authorize_roles, :force => true do |t|
      t.references :resource, :polymorphic => true
      t.string :name
      t.string :relation, :limit => 3
      t.datetime :updated_at
    end
    add_index :authorize_roles, [:resource_id, :resource_type, :relation], :unique => true, :name => "index_authorize_roles_on_resource_and_role_id"
  end

  def self.down
    drop_table :authorize_roles
    drop_table :authorize_permissions
  end
end


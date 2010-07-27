class CreateAuthorizations < ActiveRecord::Migration
  def self.up
    create_table :authorizations, :force => true do |t|
        t.string :role, :limit => 20
        t.string :token, :limit => Token.size
        t.integer :subject_id
        t.string :subject_type, :limit => 25
        t.integer :parent_id
        t.string :trustee_type, :limit => 25
        t.timestamps
    end
    add_index :authorizations, [:role, :token, :subject_id, :subject_type], :unique => true
    add_index :authorizations, [:token, :subject_id, :subject_type, :role], :unique => true
    add_index :authorizations, [:subject_id, :subject_type, :token, :role], :unique => true

    create_table :authorize_permissions, :force => true do |t|
      t.references :role, :null => false
      t.references :resource, :polymorphic => true
      t.integer :mask, :limit => 255, :default => 0, :null => false
      t.datetime :updated_at
    end
    add_index :authorize_permissions, [:role_id, :resource_id, :resource_type], :unique => true
    add_index :authorize_permissions, [:resource_id, :resource_type, :role_id], :unique => true

    create_table :authorize_roles, :force => true do |t|
      t.references :resource, :polymorphic => true
      t.string :name
      t.datetime :updated_at
    end
    add_index :authorize_roles, [:resource_type, :resource_id, :name], :unique => true
  end

  def self.down
    drop_table :authorizations
  end
end


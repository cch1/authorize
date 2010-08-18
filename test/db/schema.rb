ActiveRecord::Schema.define(:version => 0) do
  create_table :users, :force => true do |t|
    t.string :login, :limit => 80
    t.timestamps
  end
  create_table :widgets, :force => true do |t|
    t.string :name, :limit => 20
    t.timestamps
  end
  create_table :authorize_permissions, :force => true do |t|
    t.references :role, :null => false
    t.references :resource, :polymorphic => true
    t.integer :mask, :limit => 255, :default => 1, :null => false
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
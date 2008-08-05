ActiveRecord::Schema.define(:version => 0) do
  create_table :users, :force => true do |t|
    t.string :login, :limit => 80
    t.timestamps
  end
  create_table :widgets, :force => true do |t|
    t.string :name, :limit => 20
    t.timestamps
  end
  create_table :authorizations, :force => true do |t|
      t.string :role, :limit => 20
      t.integer :trustee_id
      t.string :trustee_type, :limit => 25
      t.integer :subject_id
      t.string :subject_type, :limit => 25
      t.integer :parent_id
      t.timestamps
  end
  add_index :authorizations, [:role, :trustee_id, :trustee_type, :subject_id, :subject_type], :unique
  add_index :authorizations, [:trustee_id, :trustee_type, :subject_id, :subject_type, :role], :unique
end
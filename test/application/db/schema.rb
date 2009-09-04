ActiveRecord::Schema.define(:version => 0) do
  create_table :users, :force => true do |t|
    t.string :login, :limit => 80
    t.string :authorization_token, :limit => Token.size
    t.timestamps
  end
  create_table :degenerate_users, :force => true do |t|
    t.string :login, :limit => 80
  end
  create_table :widgets, :force => true do |t|
    t.string :name, :limit => 20
    t.timestamps
  end
  create_table :authorizations, :force => true do |t|
      t.string :role, :limit => 20
      t.string :token, :limit => Token.size
      t.integer :subject_id
      t.string :subject_type, :limit => 25
      t.integer :parent_id
      t.string :trustee_type, :limit => 25
      t.timestamps
  end
  add_index :authorizations, [:role, :token, :subject_id, :subject_type], :unique => true, :name => "rts"
  add_index :authorizations, [:token, :subject_id, :subject_type, :role], :unique => true, :name => "tsr"
end
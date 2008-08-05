class CreateAuthorizations < ActiveRecord::Migration
  def self.up
    create_table :authorizations do |t|
      t.string :role, :limit => 20
      t.integer :trustee_id
      t.string :trustee_type, :limit => 25
      t.integer :subject_id
      t.string :subject_type, :limit => 25
      t.timestamps
    end
    add_index :authorizations, [:role, :trustee_id, :trustee_type, :subject_id, :subject_type], :unique
    add_index :authorizations, [:trustee_id, :trustee_type, :subject_id, :subject_type, :role], :unique
  end

  def self.down
    drop_table :authorizations
  end
end


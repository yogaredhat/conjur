Sequel.migration do
  change do
    create_table :policy_log do
      String :policy_id, null: false
      Integer :version, null: false
      foreign_key [:policy_id, :version], :policy_versions, on_delete: :cascade
      index [:policy_id, :version]
      
      column :operation, :policy_log_op, null: false
      column :table, :policy_log_table, null: false
      column :subject, :hstore, null: false      
    end
  end
end

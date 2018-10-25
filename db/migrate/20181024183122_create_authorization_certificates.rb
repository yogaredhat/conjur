Sequel.migration do
  change do
    create_table :authorization_certificates do
      foreign_key :resource_id, :resources, type: String, null: false, on_delete: :cascade
      String :privilege, null: false
      bytea :certificate, null: false
      bytea :key, null: false

      primary_key [:resource_id, :privilege]
    end
  end
end

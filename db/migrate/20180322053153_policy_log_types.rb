Sequel.migration do
  up do
    run """
      CREATE TYPE policy_log_op AS ENUM ('insert', 'delete', 'update');
      CREATE TYPE policy_log_table AS ENUM ('roles', 'role_memberships', 'resources', 'permissions', 'annotations');
      CREATE EXTENSION IF NOT EXISTS hstore;
    """
  end
  
  down do
    %w(op table).each do |type|
      run "DROP TYPE policy_log_#{type}"
    end
  end
end

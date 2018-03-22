Sequel.migration do
  TABLES = %i(roles role_memberships resources permissions annotations)

  up do
    TABLES.each do |table|
      # find the primary key of the table
      primary_key = schema(table).select{|x,s|s[:primary_key]}.map(&:first).map(&:to_s).pg_array
      run """
        CREATE OR REPLACE FUNCTION process_#{table}_log() RETURNS TRIGGER AS $$
          DECLARE
            policy_version integer;
          BEGIN
            IF (TG_OP = 'DELETE') THEN
              policy_version = MAX(version) FROM policy_versions WHERE resource_id = OLD.policy_id;
              IF policy_version IS NOT NULL THEN
                INSERT INTO public.policy_log
                SELECT 
                  OLD.policy_id, policy_version,
                  lower(TG_OP)::policy_log_op, '#{table}'::policy_log_table,
                  slice(hstore(OLD), #{literal primary_key})
                ;
              END IF;
              RETURN OLD;
            ELSE
              policy_version = MAX(version) FROM policy_versions WHERE resource_id = NEW.policy_id;
              IF policy_version IS NOT NULL THEN
                INSERT INTO public.policy_log
                SELECT 
                  NEW.policy_id, 
                  policy_version,
                  lower(TG_OP)::policy_log_op, '#{table}'::policy_log_table,
                  slice(hstore(NEW), #{literal primary_key})
                ;
              END IF;
              RETURN NEW;
            END IF;
          END;
        $$ LANGUAGE plpgsql
        SET search_path = public
      """
      run """
        CREATE TRIGGER #{table}_log
        AFTER INSERT OR UPDATE ON #{table}
        FOR EACH ROW 
        WHEN (NEW.policy_id IS NOT NULL)
        EXECUTE PROCEDURE process_#{table}_log()
      """
      run """
        CREATE TRIGGER #{table}_log_d
        AFTER DELETE ON #{table}
        FOR EACH ROW 
        WHEN (OLD.policy_id IS NOT NULL)
        EXECUTE PROCEDURE process_#{table}_log()
      """
    end
  end

  down do
    TABLES.each do |table|
      run "DROP TRIGGER #{table}_log ON #{table}"
      run "DROP TRIGGER #{table}_log_d ON #{table}"
      run "DROP FUNCTION process_#{table}_log()"
    end
  end
end

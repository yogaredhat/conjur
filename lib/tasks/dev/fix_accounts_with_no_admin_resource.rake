namespace :fix do
  desc "Search for accounts with no admin resource and create it"
  task :"missing-admin-resource", :environment do
    missing_resources_query = %{
    select * from roles
    where not exists (
      select resource_id from resources
      where role_id = resource_id
    )
    and role_id ~ '^.+:user:admin$'
    }

    Sequel::Model.db.fetch(missing_resources_query) do |row|
      Resource.create(resource_id: row[:role_id], owner: Role['!:user:account_admin'])
    end

  end
end

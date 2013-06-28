Sequel.migration do
  up do
    create_table(:accounts) do
      primary_key :id
      String :name, :null => false      
      String :endpoint, :null => false
      String :auth_key, :null => false
      Text :account_data
      DateTime :created_on
      DateTime :updated_on
      foreign_key :user_id, :users, :type => String

    end
  end

  down do
    drop_table(:accounts)
  end
end
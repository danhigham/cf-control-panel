Sequel.migration do
  up do
    create_table(:users) do
      primary_key :id, :string, :auto_increment => false, :null => false
      String :email, :null => false
      DateTime :created_on
      DateTime :updated_on
    end
  end

  down do
    drop_table(:users)
  end
end
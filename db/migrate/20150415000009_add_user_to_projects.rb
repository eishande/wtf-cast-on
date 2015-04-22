class AddUserToProjects < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :username, null:false

      t.timestamps
    end

    add_column :projects, :user_id, :integer
  end
end

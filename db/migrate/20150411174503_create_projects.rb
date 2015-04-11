class CreateProjects < ActiveRecord::Migration
  def change
    create_table :projects do |t|
      t.string :photo
      t.string :name, null:false
      t.integer :pattern_id, null:false
      t.integer :queued_id

      t.timestamps
    end
  end
end

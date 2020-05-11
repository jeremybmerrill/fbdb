class CreateJobs < ActiveRecord::Migration[6.0]
  def change
    create_table :jobs do |t|
      t.string :name
      t.integer :expected_run_rate
      t.numeric :estimated_duration

      t.timestamps
    end
  end
end

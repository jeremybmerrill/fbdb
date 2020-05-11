class CreateJobRuns < ActiveRecord::Migration[6.0]
  def change
    create_table :job_runs do |t|
      t.integer :job_id
      t.datetime :start_time
      t.datetime :end_time
      t.boolean :success

      t.timestamps
    end
  end
end

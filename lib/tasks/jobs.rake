namespace :jobs do 
  task create: :environment do
    [
      ["ad_archive_report:daily", 24, 1],
      ["text:fbpac_ads", 1, 1],
      ["text:ads", 6, 1],
      ["denormalize:payers", 1, 1],
      ["swing_states:get", 24, 1],
      ["text:topics", 6, 1],
      ["pac-archiver", 24, 1],
      ["fbpac-classifier", 1, 1],
      ["fbpac-waist-parser", 1, 1],
    ].each do |job_name, expected_run_rate, expected_duration|
      job = Job.find_or_create_by(name: job_name)
      job.expected_run_rate = expected_run_rate
      job.estimated_duration = expected_duration
      job.save
    end
  end
end

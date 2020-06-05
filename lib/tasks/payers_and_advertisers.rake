namespace :denormalize do
  desc "create objects for Payers in the DB, denormalizing DB"
  task payers: :environment do
    start = Time.now
    existing_payers = Set.new(Payer.select(:name).map(&:name))

    payers_created = 0
    Ad.unscope(:order).group(:funding_entity).count.each do |entity, cnt|
      next if existing_payers.include?(entity)
      Payer.create(name: entity)
      payers_created += 1
    end

    FbpacAd.unscope(:order).group(:paid_for_by).count.each do |entity, cnt|
      next if existing_payers.include?(entity)
      Payer.create(name: entity)
      payers_created += 1
    end

    job = Job.find_by(name: "denormalize:payers")
    job_run = job.job_runs.create({
      start_time: start,
      end_time: Time.now,
      success: true,
    })

    # RestClient.post(
    #     ENV["SLACKWH"],
    #     JSON.dump({"text" => "(5/6): Facebook payer-denormalization went swimmingly. (#{payers_created} created)" }),
    #     {:content_type => "application/json"}
    # )


  end

  task advertisers: :environment do 
    Ad.unscope(:order).group(:page_id).count.each do |page_id, cnt|
      WritablePage.find_or_create_by(page_id: page_id)
    end

    # TODO: what about FbpacAds? we don't have a page_id there, necessarily.

    RestClient.post(
        ENV["SLACKWH"],
        JSON.dump({"text" => "Facebook advertiser denormalization went swimmingly" }),
        {:content_type => "application/json"}
    )

  end
end


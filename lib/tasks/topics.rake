
# for each ad_text without topics
# throw it against the topic endpoint TOPICS_URL


namespace :text do 
  task topics: :environment do 
    counter = 0
    start = Time.now
    WritablePage.where(core: true).each do |wpage|
      wpage.ad_texts.find_in_batches(batch_size: 16) do |texts|
          counter += texts.size
        retried = 0
        begin
          AdText.classify_topic(texts)
        rescue RestClient::BadGateway
          sleep 5
          retry if retried < 3
          retried += 1
        end
        puts "successful batch -- #{counter}"
      end
    end

    AdText.includes(:ad_topics).joins(writable_ads: [:fbpac_ad]).search_for("biden OR trump").where( :ad_topics => { :ad_text_id => nil } ).find_in_batches(batch_size: 16) do |texts|
      counter += texts.size
      retried = 0
      begin
        AdText.classify_topic(texts)
      rescue RestClient::BadGateway
        sleep 5
        retry if retried < 3
        retried += 1
      end
      puts "successful batch -- #{counter}"
    end

    job = Job.find_by(name: "text:topics")
    job_run = job.job_runs.create({
      start_time: start,
      end_time: Time.now,
      success: true,
    })


    RestClient.post(
        ENV["SLACKWH"],
        JSON.dump({"text" => "(6/6): Facebook ad topic classification went swimmingly. (#{counter} batches processed)" }),
        {:content_type => "application/json"}
    ) if counter > 0
  end
end

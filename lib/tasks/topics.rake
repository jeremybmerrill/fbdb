
# for each ad_text without topics
# throw it against the topic endpoint TOPICS_URL


namespace :topics do 
  task ads: :environment do 
    ads = AdText.includes(:ad_topics).where( :ad_topics => { :ad_text_id => nil } )
    ads.each_slice(32) do |texts|
      AdText.classify_topic(texts)
    end
    RestClient.post(
        ENV["SLACKWH"],
        JSON.dump({"text" => "Facebook ad topic classification went swimmingly. (#{counter} batches processed)" }),
        {:content_type => "application/json"}
    ) if counter > 0
  end
end

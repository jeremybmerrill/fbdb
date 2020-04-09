
# for each ad_text without topics
# throw it against the topic endpoint TOPICS_URL


namespace :topics do 
  task ads: :environment do 
    ads = AdText.includes(:ad_topics).where( :ad_topics => { :ad_text_id => nil } )
    ads.each_slice(64) do |texts|
      AdText.classify_topic(texts)
    end
  end
end

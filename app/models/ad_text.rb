class AdText < ApplicationRecord
	has_many :writable_ads, primary_key: :text_hash, foreign_key: :text_hash
  has_many :ad_topics
  has_many :topics, through: :ad_topics
  has_many :ads, through: :writable_ads
  has_many :fbpac_ads, through: :writable_ads
  has_many :impressions, through: :ads

  include PgSearch::Model

  pg_search_scope :search_for, 
                  against: %i(search_text),
                  ignoring: :accents,
                  using: {
                    tsearch: {
                      negation: true,
                      dictionary: "english",
                      tsvector_column: 'tsv'
                    }
                  }

  def as_json(options)
      preset_options = {
        include: {writable_ads: {include: [:fbpac_ad, :ad]}, topics: {}}
      }
      if options[:include].is_a? Symbol
        options[:include] = Hash[options[:include], nil]
      end
      options[:include] = preset_options[:include].deep_merge(!options.nil? && options[:include] ? options[:include] : {})

      # grab *one* the ad and fbpac ad
      # holds onto text hash, I guess.
      json = super(options)
      fbpac_ad = json["writable_ads"].find{|wad| wad.has_key?("fbpac_ad")}&.dig("fbpac_ad") || {}
      fbapi_ad = json["writable_ads"].find{|wad| wad.has_key?("ad")}&.dig("ad") || {}
      topics = json.extract!("topics")
      new_json = json["writable_ads"].first.dup.without("ad", "fbpac_ad").merge(fbpac_ad.merge(fbapi_ad)).merge(topics)
      new_json["created_at"] = json["writable_ads"].map{|ad| ad.has_key?("fbpac_ad") ? ad["fbpac_ad"]["created_at"] : ad["ad"]["ad_delivery_start_time"]  }.min
      new_json["updated_at"] = json["writable_ads"].map{|ad| ad.has_key?("fbpac_ad") ? ad["fbpac_ad"]["updated_at"] : (ad["ad"]["ad_delivery_stop_time"] || ad["ad"]["ad_delivery_start_time"])  }.max

      new_json["variants"] = json["writable_ads"].map{|ad| ad.has_key?("fbpac_ad") ? ad["fbpac_ad"] : ad["ad"]  }
      new_json
  end

  def self.classify_topic(ad_texts)
    res_json = RestClient.post(ENV["TOPICS_URL"] + "/topics", {'texts' => ad_texts.map(&:text)}.to_json, {content_type: :json, accept: :json})
    res = JSON.parse(res_json)

    ad_texts.zip(res).each do |ad_text, topics|
      puts [ad_text.text, topics].inspect
      ad_text.topics = topics.map{|t|  Topic.find_or_create_by(topic: t)}
    end
  end
end


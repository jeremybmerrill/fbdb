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
      
      new_json["variants"] = json["writable_ads"].map{|ad| ad.has_key?("fbpac_ad") ? ad["fbpac_ad"] : ad["ad"]  }
      new_json
  #       # ad
  #       json["advertiser"] = (json["page"] || {})["page_name"]
  #       json.delete("page")
  #       json["funding_entity"] = json["funding_entity"] || (json["payer"] || {})["name"]
  #       json["topics"] = json["topics"]&.map{|topic| topic["topic"]}

  #       # json ad.
  #       json["ad_creation_time"] = json.delete("created_at")
  #       json["text"] = json.delete("message") # TODO: remove HTML tags
  #       json["funding_entity"] = json["paid_for_by"]
  #       # what if page_id doesn't exist?!
  # #      json["page_id"] 
  #       json["start_date"] = json.delete("created_at")
      # end
  end

    # topics.each do |topic|
    #   t = Topic.find_or_create_by(topic: topic)
    # end
    # Ad.all.each do |ad|
    #   unless ad.writable_ad
    #     wa = WritableAd.new
    #     ad.writable_ad = wa
    #     wa.save
    #   end
    #   ad.topics << Topic.find_by(topic: topics.sample)
    # end


  def self.classify_topic(ad_texts)
    puts ad_texts.map(&:text).inspect
    res_json = RestClient.post(ENV["TOPICS_URL"] + "/topics", {'texts' => ad_texts.map(&:text)}.to_json, {content_type: :json, accept: :json})
    res = JSON.parse(res_json)
    puts res.inspect
    ad_texts.zip(res).each do |ad_text, topics|
      ad_text.topics = topics.map{|t|  Topic.find_or_create_by(topic: t)}
    end
  end
end


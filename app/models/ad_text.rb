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
                  ranked_by: "id",
                  using: {
                    tsearch: {
                      negation: true,
                      dictionary: "english",
                      tsvector_column: 'tsv'
                    }
                  }

  def as_json(options)
      preset_options = {
        include: {writable_ads: {include: [:fbpac_ad]}, topics: {}}
      }
      if options[:include].is_a? Symbol
        options[:include] = Hash[options[:include], nil]
      end
      if !options[:include].nil? && options.has_key?(:include)
        options[:include] = preset_options[:include].deep_merge(!options.nil? && options[:include] ? options[:include] : {})
      end

      # grab *one* the ad and fbpac ad
      # holds onto text hash, I guess.
      json = super(options)
      fbpac_ad = json["writable_ads"].find{|wad| wad.has_key?("fbpac_ad")}&.dig("fbpac_ad") || {}
      fbapi_ad_id = json["writable_ads"].find{|wad| wad["archive_id"]}&.dig("archive_id")
      fbapi_ad = fbapi_ad_id ? options[:ads].find{|ad| ad.archive_id == fbapi_ad_id}.as_json(includes: []) : {}

      topics = json.extract!("topics")
      new_json = json["writable_ads"].first.dup.without("ad", "fbpac_ad").merge(fbpac_ad.merge(fbapi_ad)).merge(topics)
      new_json["created_at"]  = json["first_seen"]
      new_json["updated_at"]  = json["last_seen"]
      new_json["page_id"] =     json["page_id"]
      new_json["advertiser"] =  json["advertiser"]
      new_json["paid_for_by"] = json["paid_for_by"]

      # Ad lookups (from the HL server takes 130ms each)
      # So we only do it if we dont' have any FBPAC examples.
      new_json["variants"] = json["writable_ads"].select{|wad| wad.has_key?("fbpac_ad")}.first(3).map{|ad| ad["fbpac_ad"]}
      new_json["variants"] = json["writable_ads"].select{|ad| ad["archive_id"]}.first(1).map{|ad| options[:ads].find{|ad| ad.archive_id == ad["archive_id"]}  } if new_json["variants"].size == 0

      new_json
  end

  # def self.jsonify(ad_text, fbpac_ads, api_ads)
  #   json = ad_text.writable_ads.first
  #   json["topics"] = ad_text.topics
  #   json["variants"] = ad_text.writable_ads

  # end

  def self.classify_topic(ad_texts)
    res_json = RestClient.post(ENV["TOPICS_URL"] + "/topics", {'texts' => ad_texts.map(&:text)}.to_json, {content_type: :json, accept: :json})
    res = JSON.parse(res_json)

    ad_texts.zip(res).each do |ad_text, topics|
      if topics.size == 0
        topics << "none"
      end
      ad_text.topics = topics.map{|t|  Topic.find_or_create_by(topic: t)}
    end
  end
end


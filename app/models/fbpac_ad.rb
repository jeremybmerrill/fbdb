class FbpacAd < ApplicationRecord
#   belongs_to :ad, primary_key: :ad_id, foreign_key: :id # doesn't work anymore :(

  belongs_to :writable_ad, primary_key: :ad_id, foreign_key: :id

  alias_method :as_propublica_json, :as_json


  # THIS DOES NOT IN FACT GET CALLED
  def as_json(options={})
    # translating this schema to match the FB one as much as possible
    super.tap do |json|
      json["ad_creation_time"] = json.delete("created_at")
      json["text"] = json.delete("message") # TODO: remove HTML tags
      json["funding_entity"] = json["paid_for_by"]
      # what if page_id doesn't exist?!
#      json["page_id"] 
      json["start_date"] = json.delete("created_at")
      json = json.merge(json)
    end
  end



#   MISSING_STR = "missingpaidforby"

#   def as_indexed_json(options={}) # for ElasticSearch
#     json = self.as_json() # TODO: this needs a lot of work, I don't know the right way to do this, presumably I'll want writablefbpacads too
# #      json["topics"] = json["topics"]&.map{|topic| topic["topic"]}
#     json["paid_for_by"] = MISSING_STR if (json["paid_for_by"].nil? || json["paid_for_by"].empty?) && json["ad_creation_time"] && json["ad_creation_time"]> "2018-07-01" 
#     json
#   end

  def text
    Nokogiri::HTML(message).text.strip
  end
  def clean_text
    text.downcase.gsub(/\s+/, ' ').gsub(/[^a-z 0-9]/, '')
  end


  USERS_COUNT = 2442 + 5420
  def self.calculate_homepage_stats(lang) # internal only!
      political_ads_count = FbpacAd.where(lang: lang).where("political_probability > 0.70").count
      political_ads_today = FbpacAd.where(lang: lang).where("political_probability > 0.70").unscope(:order).where("created_at AT TIME ZONE 'America/New_York' > now() - interval '1 day' ").count
      starting_count = 187378 # select count(*) from fbpac_ads where created_at AT TIME ZONE 'America/New_York' <= '2020-01-01' and political_probability > 0.7 and suppressed = false and lang = 'en-US';
      cumulative_political_ads_per_week = FbpacAd.unscope(:order).where(lang: lang).where("political_probability > 0.70").where("created_at AT TIME ZONE 'America/New_York' > '2020-01-01'").group("date_trunc('week', created_at AT TIME ZONE 'America/New_York')").select("count(*) as total, date_trunc('week', created_at AT TIME ZONE 'America/New_York') as week").sort_by{|ad| ad.week}.reduce([]){|memo, ad| memo << [ad.week, (memo.last ? memo.last[1] : starting_count) + ad.total]; memo}

      {
          user_count: USERS_COUNT,
          political_ads_total: political_ads_count,
          political_ads_today: political_ads_today,
          political_ads_per_day: cumulative_political_ads_per_week
      }
  end


end

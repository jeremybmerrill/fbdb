require 'restclient'
require 'couchrest'
require "base64"

module CouchRest
    class Database
        def find(query)
          connection.post "#{path}/_find", query
        end

    end
end


class YoutubeController < ApplicationController

  before_action :force_trailing_slash

  REASONS_KINDS = [
    "This ad is based on:",
    "This ad may be based on:",
    "You've turned off ad personalization from Google, so this ad is not customized based on your data. This ad was shown based on other factors, for example:",
    "Motifs de sélection de cette annonce :" 
  ]

  @@server = CouchRest.new(ENV["DBURL"])
  @@ads_db = @@server.database("youtubeads")
  @@recs_db = @@server.database("youtuberecs")


  def group_ad_fragments(raw_ad_fragments)
    grouped_ads = raw_ad_fragments.group_by{|ad| [(ad["host"] || {})["url"], ad["user"], ad["ad"]['advertiser']&.split(" ")&.last&.downcase&.gsub("www.", '')] } # group ads that were seen by the same person on the same site and which reference the same advertiser
    ads = grouped_ads.map do |host_user_advertiser, ungrouped_ads|   # then merge the resulting ad objects into a single merged-ad object
      ads_grouped_by_reasons = ungrouped_ads.group_by{|ad| ad["ad"]["reasons"] }
      ads_grouped_by_reasons.delete(nil) # ignore ads with no reasons because they are all just type=adActionInterstitialRenderer, with advertiser a duplicate of another ad (of a different type) that's present. so learn nothing other than that there was an adActionInterstitialRenderer used at some point which I think I don't care about.
      merged_ads = ads_grouped_by_reasons.map do |reason, ads|
        types = ungrouped_ads.map{|a| a["ad"]["type"]}                 # preserving type
        ad = ungrouped_ads.reduce(&:merge)
        ad["ad"]["type"] = types
        ad
      end
      merged_ads
    end.flatten
    ads
  end

  def index
      # raw_ads = @@ads_db.all_docs(include_docs: true)["rows"].map{|a| a["doc"]}
      # grouped_ads = raw_ads.group_by{|ad| [(ad["host"] || {})["url"], ad["user"], ad["ad"]['advertiser']&.split(" ")&.last&.downcase&.gsub("www.", '')] } # group ads that were seen by the same person on the same site and which reference the same advertiser
      # ads = grouped_ads.map do |host_user_advertiser, ungrouped_ads|   # then merge the resulting ad objects into a single merged-ad object
      #   ads_grouped_by_reasons = ungrouped_ads.group_by{|ad| ad["ad"]["reasons"] }
      #   ads_grouped_by_reasons.delete(nil) # ignore ads with no reasons because they are all just type=adActionInterstitialRenderer, with advertiser a duplicate of another ad (of a different type) that's present. so learn nothing other than that there was an adActionInterstitialRenderer used at some point which I think I don't care about.
      #   merged_ads = ads_grouped_by_reasons.map do |reason, ads|
      #     types = ungrouped_ads.map{|a| a["ad"]["type"]}                 # preserving type
      #     ad = ungrouped_ads.reduce(&:merge)
      #     ad["ad"]["type"] = types
      #     ad
      #   end
      #   merged_ads
      # end.flatten
      ad_fragments = @@ads_db.all_docs(include_docs: true)["rows"].map{|a| a["doc"]}
      ads = group_ad_fragments(ad_fragments)
      @ads_count = ads.count

      political_ads = @@ads_db.find({"selector" => 
        { "$nor" => REASONS_KINDS.map{|kind| { "ad.reasons_title" => kind }} }
      })["docs"]
      @political_ads_count = political_ads.size

      @political_advertisers = political_ads.group_by{|ad| ad["ad"]["reasons_title"].split("\r\n\r\n")[0] } #  + " " + ad["ad"]["advertiser"].to_s (usually "advertiser" is actually a URL)
      @political_targetings = political_ads.map{|ad| ad["ad"]["reasons"] }.flatten.group_by{|reason| reason }.map{|reason, items| [reason, items.size]}

      @advertisers = ads.group_by{|ad| ad["ad"]["advertiser"] }.reject{|a, b| a.nil? || b.size == 1}
      @targetings = ads.map{|ad| ad["ad"]["reasons"] }.flatten.group_by{|reason| reason }.map{|reason, items| [reason, items.size]}.reject{|a, b| a.nil? }
      render template: "youtube/index"
  end

  def advertiser
    targ = Base64.urlsafe_decode64(params['targ'])
    raw_ad_fragments = @@ads_db.find({"selector" => 
        {"$or" => REASONS_KINDS.map{|kind|
          { "ad.reasons_title" => targ + "\r\n\r\n" + kind  }
        }}
    })["docs"]
    @matching_ads = group_ad_fragments(raw_ad_fragments)
    puts @matching_ads.inspect
    @query = "Reason: #{targ}"
    render template: "youtube/list"
  end

  def targeting
      targ = Base64.urlsafe_decode64(params['targ'])
      raw_ad_fragments = @@ads_db.find({"selector" => 
        {"$and" => [
        { "$nor" => REASONS_KINDS.map{|kind| { "ad.reasons_title" => kind }} },
          { "ad.reasons" => {
            "$elemMatch" => {
              "$eq" => targ
            }
          }}
        ]}
      })["docs"]
      @matching_ads = group_ad_fragments(raw_ad_fragments)
      @query = "Reason: #{targ}"
      render template: "youtube/list"
  end

  def targeting_all
      targ = Base64.urlsafe_decode64(params['targ'])
      raw_ad_fragments = @@ads_db.find({"selector" => 
        { "ad.reasons" => {
          "$elemMatch" => {
            "$eq" => targ
          }
        }}
      })["docs"]
      @matching_ads = group_ad_fragments(raw_ad_fragments)
      @query = "Reason: #{targ}"
      render template: "youtube/list"
  end

  def advertiser_all
    targ = Base64.urlsafe_decode64(params['targ'])
    raw_ad_fragments = @@ads_db.find({"selector" => 
        {"$or" => REASONS_KINDS.map{|kind|
          { "ad.advertiser" => targ  }
        }}
    })["docs"]
    @matching_ads = group_ad_fragments(raw_ad_fragments)
    @query = "Reason: #{targ}"
    render template: "youtube/list"
  end



end

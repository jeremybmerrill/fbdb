require 'digest'


# gotta make sure that `clean_text` is the same for ads from both sources. that's the whole point. see below for examples for checking.

# Ad.where("text ilike '%Charlotte on%'").first.text
# => "Let's get organized! Team Warren will convene a volunteer training in Charlotte on Tuesday, October 1. \n\nJoin us to learn more about how to spread Elizabeth’s vision for big, structural change."
# irb(main):022:0> FbpacAd.where("message ilike '%Charlotte on%'").where(advertiser: "Elizabeth Warren").first.message
# => "<p>Let's get organized! Team Warren will convene a volunteer training in Charlotte on Tuesday, October 1. </p><p> Join us to learn more about how to spread Elizabeth’s vision for big, structural change.</p>"
# irb(main):023:0> FbpacAd.where("message ilike '%Charlotte on%'").where(advertiser: "Elizabeth Warren").first.clean_text
# => "lets get organized team warren will convene a volunteer training in charlotte on tuesday october 1  join us to learn more about how to spread elizabeths vision for big structural change"
# irb(main):024:0> Ad.where("text ilike '%Charlotte on%'").first.clean_text
# => "lets get organized team warren will convene a volunteer training in charlotte on tuesday october 1   join us to learn more about how to spread elizabeths vision for big structural change"




namespace :text do 
  task ads: :environment do 
    new_ads = Ad.left_outer_joins(:writable_ad).where(writable_ads: {archive_id: nil})# ads that don't have a writable ad or whose writable ad doesn't have a text hash in it
    ads_without_text_hash = WritableAd.where("text_hash is null and archive_id is not null")

    (new_ads.map{|ad| wad = WritableAd.new;  wad.ad = ad; wad} + ads_without_text_hash).each do |wad|
      wad.text_hash = Digest::SHA1.hexdigest(wad.ad.clean_text)
      ad_text = AdText.find_or_create_by(text_hash: wad.text_hash)
      ad_text.text ||= wad.ad.clean_text
      ad_text.search_text ||= wad.ad.page.page_name + " " + wad.ad.text # TODO: add CTA text, etc.
      ad_text.save
      wad.ad_text = ad_text
      wad.save
    end
  end

  task fbpac_ads: :environment do 
    # eventually this'll be done by the ad catcher, with ATI (but for "collector ads", obvi)
    # writable_ad should be created for EVERY new ad.
    # TODO: this doesn't handle writable_ads without a text_hash set.
    def create_ad_text(wad)
        ad_text = AdText.find_or_create_by(text_hash: wad.text_hash)
        ad_text.text ||= wad.fbpac_ad.clean_text
        ad_text.search_text ||= wad.fbpac_ad.advertiser.to_s + " " + wad.fbpac_ad.text # TODO: add CTA text, etc.
        ad_text.save
        ad_text
    end
    while new_ads = FbpacAd.left_outer_joins(:writable_ad).where(writable_ads: {ad_id: nil}).limit(1000)
      new_ads.each do |ad| 
        wad = WritableAd.new
        wad.fbpac_ad = ad
        wad.text_hash = Digest::SHA1.hexdigest(wad.fbpac_ad.clean_text)
        wad.ad_text = create_ad_text(wad)
        wad.save!
      end
    end
    ads_without_text_hash = WritableAd.where("text_hash is null and ad_id is not null")
    ads_without_text_hash.each do |wad| 
        wad.text_hash = Digest::SHA1.hexdigest(wad.fbpac_ad.clean_text)
        wad.ad_text = create_ad_text(wad)
        wad.save!
    end


  end  
end

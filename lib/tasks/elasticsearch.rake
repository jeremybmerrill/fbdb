require 'elasticsearch/rails/tasks/import'
require 'digest'


namespace :text do 
	task ads: :environment do 
    new_ads = Ad.left_outer_joins(:writable_ad).where(writable_ads: {archive_id: nil})# ads that don't have a writable ad or whose writable ad doesn't have a text hash in it
    ads_without_text_hash = WritableAd.where("text_hash is null")

    (new_ads.map{|ad| wad = WritableAd.new;  wad.ad = ad; wad} + ads_without_text_hash).each do |wad|
      wad.text_hash = Digest::SHA1.hexdigest(wad.ad.clean_text)
      ad_text = AdText.find_or_create_by(text_hash: wad.text_hash)
      ad_text.text ||= wad.ad.clean_text
      ad_text.save
      wad.ad_text = ad_text
      wad.save
    end
  end

  task fbpac_ads: :environment do 
    # eventually this'll be done by the ad catcher, with ATI (but for "collector ads", obvi)
    new_ads = FbpacAd.left_outer_joins(:writable_ad).where(writable_ads: {ad_id: nil}) # ads that don't have a writable ad or whose writable ad doesn't have a text hash in it
    (new_ads.map{|ad| wad = WritableAd.new;  wad.fbpac_ad = ad; wad}).each do |wad|
      wad.text_hash = Digest::SHA1.hexdigest(wad.fbpac_ad.clean_text)
      ad_text = AdText.find_or_create_by(text_hash: wad.text_hash)
      ad_text.text ||= wad.fbpac_ad.clean_text
      ad_text.save
      wad.ad_text = ad_text
      wad.save!
    end
  end  

  
# rake environment elasticsearch:import:model CLASS='FbpacAd' FORCE=y

end 
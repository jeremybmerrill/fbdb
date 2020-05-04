

SWING_STATES = ['Michigan', 'Wisconsin', 'Pennsylvania', 'Florida', 'Arizona', 'North Carolina', 'Nebraska']
LEANS = ["Maine", "Minnesota", "New Hampshire", "Georgia", "Texas"]
# per Cook political report, 4/22/2020 https://cookpolitical.com/sites/default/files/2020-03/EC%20030920.4.pdf
# Nebraska is just one CD, of course.

namespace :swing_states do 
  task get: :environment do 
    
    count = 0

    old_swing_state_ads = Set.new(WritableAd.where(swing_state_ad: true).select("archive_id").map(&:archive_id))

    advertiser_new_swing_ads_count = {}

    WritablePage.where(core: true).each do |wpage|
      resps = Ad.connection.execute("select ads.archive_id, ad_creative_body, sum(spend_percentage), array_to_json(array_agg(case when spend_percentage > 0.05 then region else null end order by region)) as states from ads join region_impressions using (archive_id) join impressions using (archive_id) where region in ('#{SWING_STATES.join("','")}') and spend_percentage < 0.90 and page_id  = #{wpage.page_id} and min_impressions > 0 and ad_creation_time > '#{(Date.today - 60).to_s}' and (ad_delivery_stop_time is null or ad_delivery_stop_time > '#{(Date.today - 30).to_s}') group by ads.archive_id, ad_creative_body having sum(spend_percentage) > 0.8").to_a
      puts "found #{resps.size} for #{wpage.page.page_name}"
      resps.each do |ad_row|
        count += 1
        wad = WritableAd.find_by(archive_id: ad_row["archive_id"])
        if wad.nil?
          ad = Ad.find_by(archive_id: ad_row["archive_id"])
          wad = ad.create_writable_ad!
          ad.create_ad_text!(wad)
        end
        unless wad.swing_state_ad
          advertiser_new_swing_ads_count[wad.page_id] ||= 0
          advertiser_new_swing_ads_count[wad.page_id] += 1
        end
        old_swing_state_ads.delete(wad.archive_id)
        wad.swing_state_ad = true
        wad.states = JSON.load(ad_row["states"]).compact
        wad.save!
        wad.copy_screenshot_to_s3!
      end
    end

    stopped_being_swing_state_ads = old_swing_state_ads.count
    WritableAd.where(archive_id: stopped_being_swing_state_ads).update_all(swing_state_ad: false)

    new_advertisers_text = advertiser_new_swing_ads_count.map{|page_id, cnt| "#{Page.find(page_id).page_name}: #{cnt}"}.join(", ")

    msg = "(7/7): found #{count} swing state ads; #{stopped_being_swing_state_ads} stopped being swing state ads; #{new_advertisers_text}"
    puts msg

    RestClient.post(
        ENV["SLACKWH"],
        JSON.dump({"text" => msg }),
        {:content_type => "application/json"}
    ) if count > 0 && ENV["SLACKWH"]
  end
  task clear: :environment do 
  #   WritableAd.update_all(swing_state_ad: false)
  #   WritableAd.update_all(states: [])
  #   RestClient.post(
  #       ENV["SLACKWH"],
  #       JSON.dump({"text" => "(7/8): cleared swing state ads."}),
  #       {:content_type => "application/json"}
  #   ) if ENV["SLACKWH"]
  end
end

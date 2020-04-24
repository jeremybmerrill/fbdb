

SWING_STATES = ['Michigan', 'Wisconsin', 'Pennsylvania', 'Florida', 'Arizona', 'North Carolina', 'Nebraska']
LEANS = ["Maine", "Minnesota", "New Hampshire", "Georgia", "Texas"]
# per Cook political report, 4/22/2020 https://cookpolitical.com/sites/default/files/2020-03/EC%20030920.4.pdf
# Nebraska is just one CD, of course.

namespace :swing_states do 
  task get: :environment do 

    WritablePage.where(core: true).each do |wpage|
      resps = Ad.connection.execute("select ads.archive_id, ad_creative_body, sum(spend_percentage), array_to_json(array_agg(case when spend_percentage > 0.05 then region else null end order by region)) as states from ads join region_impressions using (archive_id) join impressions using (archive_id) where region in ('#{SWING_STATES.join("','")}') and spend_percentage < 0.90 and page_id  = #{wpage.page_id} and min_impressions > 0 and ad_creation_time > '#{(Date.today - 60).to_s}' and (ad_delivery_stop_time is null or ad_delivery_stop_time > '#{(Date.today - 30).to_s}') group by ads.archive_id, ad_creative_body having sum(spend_percentage) > 0.8").to_a
      puts "found #{resps.size} for #{wpage.page.page_name}"
      resps.each do |ad_row|
        wad = WritableAd.find_by(archive_id: ad_row["archive_id"])
        if wad.nil?
          ad = Ad.find_by(archive_id: ad_row["archive_id"])
          wad = ad.create_writable_ad!
          ad.create_ad_text!(wad)
        end
        wad.swing_state_ad = true
        wad.states = JSON.load(ad_row["states"])
        wad.save!
        wad.copy_screenshot_to_s3!
      end
    end
  end
  task clear: :environment do 
    WritableAd.update_all(swing_state_ad: false)
    WritableAd.update_all(states: [])
  end
end

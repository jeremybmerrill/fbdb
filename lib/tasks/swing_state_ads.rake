

SWING_STATES = ['Michigan', 'Wisconsin', 'Pennsylvania', 'Florida', 'Arizona', 'North Carolina', 'Nebraska', 'Georgia', 'Iowa', 'Ohio']
LEAN_STATES = ["Maine", "Minnesota", "New Hampshire", "Texas", 'Virginia', 'Colorado', 'Nevada']
# per Cook political report, 4/22/2020 https://cookpolitical.com/sites/default/files/2020-03/EC%20030920.4.pdf
# Nebraska is just one CD, of course.

# let's ignore the leans, entirely (from both numerator and denominator)


SWING_STATE_CUTOFF = 0.80

namespace :swing_states do 
  task get: :environment do 
    start = Time.now
    count_swing_state_ads = 0
    count_stopped_being_swing_state_ads = 0
    old_swing_state_ads = Set.new(WritableAd.where(swing_state_ad: true).select("text_hash").map(&:text_hash))

    advertiser_new_swing_ads_count = {}

    WritablePage.where(core: true).each do |wpage|
      puts ""
      puts wpage.page.page_name
      resp = Ad.connection.execute("
          SELECT 
          ad_creative_body, 
          region, 
          min(ads.archive_id) archive_id, 
          sum(spend_percentage * min_spend) as min_spend
        FROM ads join region_impressions using (archive_id) join impressions using (archive_id)
        where page_id = #{wpage.page_id}  and ad_creation_time > '#{(Date.today - 60).to_s}'
        and (ad_delivery_stop_time is null or ad_delivery_stop_time > '#{(Date.today - 30).to_s}') group by ad_creative_body, region;")
      ads = resp.group_by{|row| row["ad_creative_body"]}.map do |ad_creative_body, state_rows| 
        non_lean_state_rows = state_rows.reject{|state_row| LEAN_STATES.include?(state_row["region"]) }
        {
          ad_creative_body: ad_creative_body,
          total_min_spend: non_lean_state_rows.map{|row| row["min_spend"].to_i }.reduce(&:+) || 0, 
          archive_id: non_lean_state_rows.map{|row| row["archive_id"]}[0],
          swing_state_min_spend: non_lean_state_rows.select{|state_row| SWING_STATES.include?(state_row["region"])}.map{|state_row| state_row["min_spend"].to_i }.reduce(&:+) || 0,
          swing_states: non_lean_state_rows.select{|state_row| SWING_STATES.include?(state_row["region"]) }.select{|state_row| (state_row["min_spend"].to_f / state_rows.map{|row| row["min_spend"].to_i }.reduce(&:+)) > 0.05 }.map{|state_row| state_row["region"]}
        }
      end
      grouped = ads.group_by{|ad_row| (ad_row[:swing_state_min_spend].to_f / ad_row[:total_min_spend] > SWING_STATE_CUTOFF) && ad_row[:swing_states].size > 1 }
      swing_state_ads = grouped[true]
      non_swing_state_ads = grouped[false]
      

      swing_state_ads.each do |ad_row|
        count_swing_state_ads += 1
        puts ad_row
        wad = WritableAd.find_by(archive_id: ad_row[:archive_id])
        if wad.nil?
          ad = Ad.find_by(archive_id: ad_row[:archive_id])
          wad = ad.create_writable_ad!
          ad.create_ad_text!(wad)
        end
        unless wad.swing_state_ad # bookkeeping, just for notifications
          advertiser_new_swing_ads_count[wad.page_id] ||= 0
          advertiser_new_swing_ads_count[wad.page_id] += 1
        end
        old_swing_state_ads.delete(wad.text_hash)
        wad.swing_state_ad = true
        wad.states = ad_row[:swing_states]
        wad.save!
        wad.copy_screenshot_to_s3! if ENV['AWS_REGION']
      end if swing_state_ads
      non_swing_state_ads.each do |ad_row|
        text_hash = Digest::SHA1.hexdigest(ad_row[:ad_creative_body].to_s.strip.downcase.gsub(/\s+/, ' ').gsub(/[^a-z 0-9]/, ''))
        if old_swing_state_ads.include?(text_hash)
          count_stopped_being_swing_state_ads += 1
        end
      end if non_swing_state_ads
    end
    stopped_being_swing_state_ads = old_swing_state_ads
    WritableAd.where(archive_id: stopped_being_swing_state_ads).update_all(swing_state_ad: false)

    new_advertisers_text = advertiser_new_swing_ads_count.map{|page_id, cnt| "#{Page.find(page_id).page_name}: #{cnt}"}.join(", ")

    # TODO should alert ads that stopped being swing state ads but didn't merely age out
    msg = "found #{count_swing_state_ads} current swing state ads;  #{new_advertisers_text}, <@UBZC2ATRN>"
    puts msg

    job = Job.find_by(name: "swing_states:get")
    job_run = job.job_runs.create({
      start_time: start,
      end_time: Time.now,
      success: true,
    })

    RestClient.post(
        ENV["SLACKWH"],
        JSON.dump({"text" => msg }),
        {:content_type => "application/json"}
    ) if ENV["SLACKWH"]    
  end
  task old_get: :environment do 
    start = Time.now
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
        unless wad.swing_state_ad # bookkeeping, just for notifications
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

    stopped_being_swing_state_ads = old_swing_state_ads
    WritableAd.where(archive_id: stopped_being_swing_state_ads).update_all(swing_state_ad: false)

    new_advertisers_text = advertiser_new_swing_ads_count.map{|page_id, cnt| "#{Page.find(page_id).page_name}: #{cnt}"}.join(", ")

    msg = "found #{count} swing state ads; #{stopped_being_swing_state_ads.count} stopped being swing state ads; #{new_advertisers_text}, <@UBZC2ATRN>"
    puts msg

    job = Job.find_by(name: "swing_states:get")
    job_run = job.job_runs.create({
      start_time: start,
      end_time: Time.now,
      success: true,
    })

    RestClient.post(
        ENV["SLACKWH"],
        JSON.dump({"text" => msg }),
        {:content_type => "application/json"}
    ) if ENV["SLACKWH"]
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

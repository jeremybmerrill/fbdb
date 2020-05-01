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


# wilderness project, UNICEF, etc.
BORING_ADVERTISERS = [73970658023, 54684090291, 81517275796, 33110852384, 15239367801, 11131463701]


namespace :text do 
  task clear: :environment do 
    WritableAd.update_all(text_hash: nil)
  end

  task ads: :environment do 

    def top_advertiser_page_ids 
      most_recent_lifelong_report_id = AdArchiveReport.where(kind: 'lifelong', loaded: true).order(:scrape_date).last.id
      starting_point_id = AdArchiveReport.starting_point.id
      top_advertiser_page_ids = ActiveRecord::Base.connection.exec_query("select start.page_id, start.page_name, current_sum_amount_spent - start_sum_amount_spent from 
        (SELECT ad_archive_report_pages.page_id as page_id, 
                  ad_archive_report_pages.page_name, 
                  sum(amount_spent)  current_sum_amount_spent
                  FROM ad_archive_report_pages 
                  WHERE ad_archive_report_pages.ad_archive_report_id = #{most_recent_lifelong_report_id}
                  GROUP BY page_id, page_name) current JOIN (SELECT ad_archive_report_pages.page_id as page_id, 
                  ad_archive_report_pages.page_name, 
                  sum(amount_spent)  start_sum_amount_spent
                  FROM ad_archive_report_pages 
                  WHERE ad_archive_report_pages.ad_archive_report_id = #{starting_point_id}
                  GROUP BY page_id, page_name) start on start.page_id = current.page_id order by current_sum_amount_spent - start_sum_amount_spent desc limit 10 "
                  ).rows.map(&:first)
      top_advertiser_page_ids - BORING_ADVERTISERS
    end

    new_ads = Ad.left_outer_joins(:writable_ad).where(writable_ads: {archive_id: nil}). # ads that don't have a writable ad or whose writable ad doesn't have a text hash in it
      # where(page_id: top_advertiser_page_ids) # FOR NOW, limited to the top handful of advertisers
            where("ad_creation_time > '2020-04-01'")
    ads_without_text_hash = WritableAd.where("text_hash is null and archive_id is not null")

    ads_hashed = 0
    batch_size = 5000
    new_ads.find_in_batches(batch_size: batch_size).map do |batch|
      puts "batch (new ads)"
      batch.map(&:create_writable_ad!).each do |wad|
          wad.ad_text = wad.ad&.create_ad_text!(wad)
          wad.save
          ads_hashed += 1
      end
    end
    ads_without_text_hash.find_in_batches(batch_size: batch_size).each do |batch|
      puts "batch (ads w/o text hash)"
      batch.each do |wad|
        wad.ad_text = wad.ad.create_ad_text!(wad)
        wad.save
        ads_hashed += 1
      end
    end
    RestClient.post(
        ENV["SLACKWH"],
        JSON.dump({"text" => "(4/6): text hashing for FB API ads went swimmingly. (#{ads_hashed} ads hashed)" }),
        {:content_type => "application/json"}
    ) if ads_hashed > 0 && ENV["SLACKWH"]
  end

  task fbpac_ads: ["page_ids:fbpac_ads", :environment] do 
    # eventually this'll be done by the ad catcher, with ATI (but for "collector ads", obvi)
    # writable_ad should be created for EVERY new ad.
    counter = 0

    batch_size = 500
    FbpacAd.left_outer_joins(:writable_ad).where(writable_ads: {ad_id: nil}).find_in_batches(batch_size: batch_size).each do |new_ads|
      counter += 1
      puts batch_size * counter
      new_ads.each(&:create_writable_ad!)
    end
    WritableAd.where("text_hash is null and ad_id is not null").find_in_batches(batch_size: batch_size).each do |ads_without_text_hash|
      ads_without_text_hash.each do |wad| 
          wad.text_hash = Digest::SHA1.hexdigest(wad.fbpac_ad.clean_text)
          wad.ad_text = create_ad_text!(wad)
          wad.save!
      end
    end
    RestClient.post(
        ENV["SLACKWH"],
        JSON.dump({"text" => "(3/6): text hashing for collector ads went swimmingly. (#{counter} batches processed)" }),
        {:content_type => "application/json"}
    ) if counter > 0 && ENV["SLACKWH"]


  end  
end

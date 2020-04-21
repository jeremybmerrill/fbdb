require 'nokogiri'

namespace :page_ids do 

  task fbpac_ads: :environment do 
    counter = 0

    batch_size = 500
    FbpacAd.where("created_at > '2020-01-01'").where("page_id is null").find_in_batches(batch_size: batch_size) do |ads|
      ads.each do |ad|
        next if ad.html.include?("ego_unit")
        match = ad.html.match(/data-hovercard="https:\/\/www.facebook.com\/(\d+)"/)
        next unless match
        ad.page_id = match[1].to_i
        ad.save
      end
    end

    RestClient.post(
        ENV["SLACKWH"],
        JSON.dump({"text" => "page ID parsing for collector ads went swimmingly. (#{counter} batches processed)" }),
        {:content_type => "application/json"}
    ) if counter > 0 && ENV["SLACKWH"]
  end  
end

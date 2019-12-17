
require 'csv'
namespace :fake do 
	task topics: :environment do
		topics = ["immigrationfake", "budgetfake", "corruptionfake", "abortionfake" ]
		topics.each do |topic|
			t = Topic.find_or_create_by(topic: topic)
		end
		Ad.all.each do |ad|
			unless ad.writable_ad
				wa = WritableAd.new
				ad.writable_ad = wa
				wa.save
			end
			ad.topics << Topic.find_by(topic: topics.sample)
		end
	end
end

namespace :interim do 
	task ad_ids: :environment do 
		CSV.open("/Users/jmerrill/code/impeachmentads/impeachment_ad_ids.csv").each do |row|
			ad_archive_id = row[0]
			ad_id = row[1]
			ad = Ad.find_by(archive_id: ad_archive_id)
			next unless ad
			ad.ad_id = ad_id.to_i
			ad.save!(validate: false)
		end

	end

end
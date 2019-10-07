namespace :denormalize do
	desc "create objects for Payers in the DB, denormalizing DB"
	task payers: :environment do
		existing_payers = Set.new(Payer.select(:name).map(&:name))
		Ad.group(:funding_entity).count.each do |entity, cnt|
			next if existing_payers.include?(entity)
			Payer.create(name: entity)
		end
	end

	task advertisers: :environment do 
		Ad.group(:page_id).count.each do |page_id, cnt|
			page_id
		end
	end
end



namespace :fake do 
	task topics: :environment do
		topics = ["immigration (fake)", "budget (fake)", "corruption (fake)", "abortion (fake)" ]
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
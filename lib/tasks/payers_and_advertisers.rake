namespace :denormalize do
	desc "create objects for Payers in the DB, denormalizing DB"
	task payers: :environment do
		existing_payers = Set.new(Payer.select(:name).map(&:name))
		Ad.unscope(:order).group(:funding_entity).count.each do |entity, cnt|
			next if existing_payers.include?(entity)
			Payer.create(name: entity)
		end
	end

	task advertisers: :environment do 
		Ad.unscope(:order).group(:page_id).count.each do |page_id, cnt|
			page_id
		end
	end
end


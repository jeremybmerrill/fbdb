class AdText < ApplicationRecord
	has_many :writable_ads, primary_key: :text_hash, foreign_key: :text_hash
	has_many :fbpac_ads, primary_key: :text_hash, foreign_key: :text_hash
	# has_many :collector_ads
end

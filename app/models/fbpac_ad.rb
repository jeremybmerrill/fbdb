class FbpacAd < ApplicationRecord
	belongs_to :ad, primary_key: :ad_id, foreign_key: :id
end

class WritableAd < ApplicationRecord
	belongs_to :ad, primary_key: :archive_id, foreign_key: :archive_id
end
